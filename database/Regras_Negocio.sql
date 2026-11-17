BEGIN;

-- 1. FUNCTIONS
-- Function 1: Validação prévia de elegibilidade de dispensação (RN01 e RN02)
CREATE OR REPLACE FUNCTION public.fn_verificar_disponibilidade_dose(
    p_id_tratamento uuid
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    v_qtd_dose integer;
    v_qtd_estoque integer;
    v_tratamento_ativo boolean;
BEGIN
    SELECT t.quantidade_dose, t.ativo, a.quantidade_atual
    INTO v_qtd_dose, v_tratamento_ativo, v_qtd_estoque
    FROM public.tratamento t
    JOIN public.abastecimento a 
      ON a.id_medicamento = t.id_medicamento 
     AND a.id_usuario = t.id_usuario
     AND a.ativo = true
    WHERE t.id_tratamento = p_id_tratamento;

    IF NOT FOUND OR NOT v_tratamento_ativo THEN
        RETURN false;
    END IF;

    RETURN COALESCE(v_qtd_estoque, 0) >= v_qtd_dose;
END;
$$;

-- Function 2: Cálculo da taxa de adesão do paciente (%)
CREATE OR REPLACE FUNCTION public.fn_calcular_taxa_adesao(
    p_id_paciente uuid,
    p_dias integer DEFAULT 30
)
RETURNS numeric(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total integer;
    v_no_prazo integer;
BEGIN
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE d.status = 'RETIRADA')
    INTO v_total, v_no_prazo
    FROM public.dispensacao d
    JOIN public.tratamento t ON t.id_tratamento = d.id_tratamento
    JOIN public.medicamento m ON m.id_medicamento = t.id_medicamento
    WHERE m.id_paciente = p_id_paciente
      AND d.status IN ('RETIRADA', 'RETIRADA_COM_ATRASO', 'ATRASADA', 'FALHA')
      AND d.data_hora_programada >= (now() - (p_dias || ' days')::interval);

    IF v_total = 0 THEN
        RETURN 100.00;
    END IF;

    RETURN ROUND((v_no_prazo::numeric / v_total::numeric) * 100.0, 2);
END;
$$;

-- Function 3: Estimativa de autonomia em dias do abastecimento ativo
CREATE OR REPLACE FUNCTION public.fn_dias_autonomia_abastecimento(
    p_id_abastecimento uuid
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_qtd_atual integer;
    v_consumo_diario numeric;
BEGIN
    SELECT a.quantidade_atual,
           COALESCE(SUM(t.quantidade_dose * (1440.0 / t.intervalo_minutos)), 0)
    INTO v_qtd_atual, v_consumo_diario
    FROM public.abastecimento a
    LEFT JOIN public.tratamento t 
      ON t.id_medicamento = a.id_medicamento 
     AND t.ativo = true
    WHERE a.id_abastecimento = p_id_abastecimento
    GROUP BY a.quantidade_atual;

    IF NOT FOUND OR v_consumo_diario <= 0 OR v_qtd_atual <= 0 THEN
        RETURN 0;
    END IF;

    RETURN FLOOR(v_qtd_atual / v_consumo_diario)::integer;
END;
$$;


-- 2. TRIGGERS
-- Trigger 1: Impede dupla dispensação (RN01) e alteração de histórico (RN03)
CREATE OR REPLACE FUNCTION public.tg_fn_validar_dispensacao()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- RN03: Bloqueia alteração retroativa em registros históricos finalizados
    IF TG_OP = 'UPDATE' THEN
        IF OLD.status IN ('RETIRADA', 'RETIRADA_COM_ATRASO', 'FALHA', 'CANCELADA') THEN
            -- Permite reagendamento explícito apenas se voltar para PROGRAMADA sem retirada
            IF NOT (NEW.status = 'PROGRAMADA' AND OLD.retirada_confirmada_sensor = false) THEN
                RAISE EXCEPTION 'RN03: Registros históricos de dispensação (%) não podem ser alterados.', OLD.id_dispensacao;
            END IF;
        END IF;

        -- RN01: Impede liberar novamente um agendamento já liberado sem reagendamento explícito
        IF OLD.status IN ('LIBERADA', 'ATRASADA') AND NEW.status = 'LIBERADA' THEN
            RAISE EXCEPTION 'RN01: Não é permitida mais de uma dispensação para o mesmo agendamento sem reagendamento explícito.';
        END IF;
    END IF;

    -- RN01: Exige quantidade definida para liberação
    IF NEW.status = 'LIBERADA' AND COALESCE(NEW.quantidade_liberada, 0) <= 0 THEN
        RAISE EXCEPTION 'RN01: A liberação exige uma quantidade de dose maior que zero.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_validar_e_auditar_dispensacao
BEFORE INSERT OR UPDATE ON public.dispensacao
FOR EACH ROW
EXECUTE FUNCTION public.tg_fn_validar_dispensacao();

-- Trigger 2: Gera alerta automático de ESTOQUE_BAIXO ao debitar abastecimento
CREATE OR REPLACE FUNCTION public.tg_fn_alerta_estoque_baixo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_limite integer;
    v_nome_med varchar(180);
BEGIN
    v_limite := GREATEST(3, FLOOR(NEW.quantidade_inicial * 0.20)::integer);

    IF NEW.ativo = true 
       AND NEW.quantidade_atual <= v_limite 
       AND OLD.quantidade_atual > v_limite THEN
        
        SELECT nome INTO v_nome_med 
        FROM public.medicamento 
        WHERE id_medicamento = NEW.id_medicamento;

        INSERT INTO public.alerta (
            id_usuario, id_abastecimento, tipo, mensagem
        ) VALUES (
            NEW.id_usuario,
            NEW.id_abastecimento,
            'ESTOQUE_BAIXO',
            'Estoque baixo para ' || COALESCE(v_nome_med, 'medicamento') || 
            ': restam ' || NEW.quantidade_atual || ' unidade(s) no compartimento.'
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_alerta_estoque_baixo
AFTER UPDATE OF quantidade_atual ON public.abastecimento
FOR EACH ROW
EXECUTE FUNCTION public.tg_fn_alerta_estoque_baixo();

-- Trigger 3: Protege histórico contra exclusão (RN03)
CREATE OR REPLACE FUNCTION public.tg_fn_proteger_historico_dispensacao()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'RN03: Exclusão física proibida na tabela dispensacao para preservação de auditoria.';
END;
$$;

CREATE TRIGGER tg_proteger_historico_dispensacao
BEFORE DELETE ON public.dispensacao
FOR EACH ROW
EXECUTE FUNCTION public.tg_fn_proteger_historico_dispensacao();


-- 3. PROCEDURES
-- Procedure 1: Executa a dispensação aplicando RN01, RN02 e RN03
CREATE OR REPLACE PROCEDURE public.sp_registrar_dispensacao(
    p_id_dispensacao uuid,
    p_chave_evento varchar(120)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_disp record;
    v_trat record;
    v_abast record;
BEGIN
    -- Busca agendamento
    SELECT * INTO v_disp 
    FROM public.dispensacao 
    WHERE id_dispensacao = p_id_dispensacao;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RN01: Agendamento de dispensação (%) não encontrado.', p_id_dispensacao;
    END IF;

    -- RN01: Valida estado do agendamento
    IF v_disp.status <> 'PROGRAMADA' THEN
        RAISE EXCEPTION 'RN01: Agendamento % não está disponível para liberação (status atual: %).',
            p_id_dispensacao, v_disp.status;
    END IF;

    -- Busca tratamento e dose configurada
    SELECT * INTO v_trat 
    FROM public.tratamento 
    WHERE id_tratamento = v_disp.id_tratamento AND ativo = true;

    IF NOT FOUND OR v_trat.quantidade_dose <= 0 THEN
        RAISE EXCEPTION 'RN01: Tratamento inativo ou sem quantidade de dose definida.';
    END IF;

    -- Busca estoque ativo do medicamento
    SELECT * INTO v_abast 
    FROM public.abastecimento 
    WHERE id_medicamento = v_trat.id_medicamento 
      AND id_usuario = v_trat.id_usuario
      AND ativo = true
    FOR UPDATE;

    -- RN02: Verifica estoque suficiente; se faltar, registra ocorrência e falha
    IF NOT FOUND OR v_abast.quantidade_atual < v_trat.quantidade_dose THEN
        UPDATE public.dispensacao
        SET status = 'FALHA',
            chave_evento_dispositivo = p_chave_evento,
            quantidade_liberada = 0
        WHERE id_dispensacao = p_id_dispensacao;

        INSERT INTO public.alerta (
            id_usuario, id_dispensacao, id_abastecimento, tipo, mensagem
        ) VALUES (
            v_disp.id_usuario,
            p_id_dispensacao,
            v_abast.id_abastecimento,
            'FALHA_DISPENSACAO',
            'RN02: Estoque insuficiente no compartimento para dispensar ' || v_trat.quantidade_dose || ' unidade(s).'
        );
        RETURN;
    END IF;

    -- Baixa no estoque (dispara tg_alerta_estoque_baixo se atingir limite)
    UPDATE public.abastecimento
    SET quantidade_atual = quantidade_atual - v_trat.quantidade_dose
    WHERE id_abastecimento = v_abast.id_abastecimento;

    -- RN03: Atualiza o registro individual da dispensação
    UPDATE public.dispensacao
    SET id_abastecimento = v_abast.id_abastecimento,
        chave_evento_dispositivo = p_chave_evento,
        data_hora_liberacao = now(),
        prazo_retirada = now() + (v_trat.tolerancia_retirada_minutos || ' minutes')::interval,
        status = 'LIBERADA',
        quantidade_liberada = v_trat.quantidade_dose
    WHERE id_dispensacao = p_id_dispensacao;

    -- Atualiza estado do tratamento
    UPDATE public.tratamento
    SET estado_contagem = 'AGUARDANDO_RETIRADA'
    WHERE id_tratamento = v_trat.id_tratamento;
END;
$$;

-- Procedure 2: Reabastecimento seguro de compartimento
CREATE OR REPLACE PROCEDURE public.sp_reabastecer_compartimento(
    p_id_usuario uuid,
    p_id_medicamento uuid,
    p_id_compartimento uuid,
    p_quantidade integer,
    p_data_limite timestamptz DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_quantidade <= 0 THEN
        RAISE EXCEPTION 'A quantidade abastecida deve ser maior que zero.';
    END IF;

    -- Desativa o abastecimento anterior do mesmo compartimento (respeita ux_abastecimento_ativo_compartimento)
    UPDATE public.abastecimento
    SET ativo = false
    WHERE id_compartimento = p_id_compartimento
      AND id_usuario = p_id_usuario
      AND ativo = true;

    -- Insere o novo lote ativo
    INSERT INTO public.abastecimento (
        id_usuario, id_medicamento, id_compartimento,
        quantidade_inicial, quantidade_atual,
        data_abastecimento, data_limite_armazenamento, ativo
    ) VALUES (
        p_id_usuario, p_id_medicamento, p_id_compartimento,
        p_quantidade, p_quantidade,
        now(), p_data_limite, true
    );
END;
$$;

-- Procedure 3: Confirmação de retirada pelo sensor e agendamento da próxima dose
CREATE OR REPLACE PROCEDURE public.sp_confirmar_retirada_sensor(
    p_id_dispensacao uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_disp record;
    v_trat record;
    v_novo_status varchar(25);
    v_agora timestamptz := now();
    v_proxima timestamptz;
BEGIN
    SELECT * INTO v_disp 
    FROM public.dispensacao 
    WHERE id_dispensacao = p_id_dispensacao;

    IF NOT FOUND OR v_disp.status NOT IN ('LIBERADA', 'ATRASADA') THEN
        RAISE EXCEPTION 'Dispensação % não está aguardando retirada.', p_id_dispensacao;
    END IF;

    SELECT * INTO v_trat 
    FROM public.tratamento 
    WHERE id_tratamento = v_disp.id_tratamento;

    IF v_disp.prazo_retirada IS NOT NULL AND v_agora > v_disp.prazo_retirada THEN
        v_novo_status := 'RETIRADA_COM_ATRASO';

        INSERT INTO public.alerta (
            id_usuario, id_dispensacao, id_abastecimento, tipo, mensagem
        ) VALUES (
            v_disp.id_usuario, v_disp.id_dispensacao, v_disp.id_abastecimento,
            'ATRASO_RETIRADA',
            'A dose foi retirada após o prazo de tolerância de ' || v_trat.tolerancia_retirada_minutos || ' minutos.'
        );
    ELSE
        v_novo_status := 'RETIRADA';
    END IF;

    -- Atualiza a dispensação concluída
    UPDATE public.dispensacao
    SET data_hora_retirada = v_agora,
        retirada_confirmada_sensor = true,
        status = v_novo_status
    WHERE id_dispensacao = p_id_dispensacao;

    -- Calcula próximo ciclo baseado no intervalo (tratamento por intervalo)
    v_proxima := v_agora + (v_trat.intervalo_minutos || ' minutes')::interval;

    UPDATE public.tratamento
    SET primeira_retirada_em = COALESCE(primeira_retirada_em, v_agora),
        ultima_retirada_em = v_agora,
        proxima_dose_em = v_proxima,
        estado_contagem = 'CONTANDO'
    WHERE id_tratamento = v_trat.id_tratamento;

    -- Cria próximo agendamento programado automaticamente
    INSERT INTO public.dispensacao (
        id_usuario, id_tratamento, id_abastecimento,
        data_hora_programada, status
    ) VALUES (
        v_trat.id_usuario, v_trat.id_tratamento, v_disp.id_abastecimento,
        v_proxima, 'PROGRAMADA'
    );
END;
$$;

COMMIT;