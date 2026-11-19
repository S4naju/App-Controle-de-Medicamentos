--FUNCTIONS 
-- verifica se há dose disponível no estoque, calcula a taxa de adesão do paciente nos últimos 30 dias e estima quantos dias o estoque atual ainda dura
SELECT 
    public.fn_verificar_disponibilidade_dose('80000000-0000-4000-8000-000000000001') AS dose_disponivel,
    public.fn_calcular_taxa_adesao('20000000-0000-4000-8000-000000000001', 30) AS taxa_adesao_pct,
    public.fn_dias_autonomia_abastecimento('70000000-0000-4000-8000-000000000001') AS dias_autonomia;


---PROCEDURES
-- 1. dispensão 06  inicia como PROGRAMADA e depois libera a dose
CALL public.sp_registrar_dispensacao(
    '90000000-0000-4000-8000-000000000006',
    'EVT-TESTE-APD2-001'
);

-- conferir alteração de status para LIBERADA e baixa no abastecimento 06
SELECT id_dispensacao, status, quantidade_liberada, data_hora_liberacao, prazo_retirada
FROM public.dispensacao
WHERE id_dispensacao = '90000000-0000-4000-8000-000000000006';

-- 2. Dispensação 01 está LIBERADA para o paciente
CALL public.sp_confirmar_retirada_sensor('90000000-0000-4000-8000-000000000001');

-- conferir retirada confirmada e novo agendamento PROGRAMADA gerado
SELECT id_dispensacao, status, data_hora_programada, data_hora_retirada, retirada_confirmada_sensor
FROM public.dispensacao
WHERE id_tratamento = '80000000-0000-4000-8000-000000000001'
ORDER BY data_hora_programada DESC;

-- 3. reposição de 30 unidades no compartimento 01
CALL public.sp_reabastecer_compartimento(
    '10000000-0000-4000-8000-000000000001',
    '60000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000001',
    30,
    now() + interval '90 days'
);

-- conferir se o lote anterior foi desativado e o insere um novo lote ativo
SELECT id_abastecimento, quantidade_inicial, quantidade_atual, ativo
FROM public.abastecimento
WHERE id_compartimento = '40000000-0000-4000-8000-000000000001';


--TRIGGERS
-- 1. reduz saldo do compartimento 01 para 2 unidades e disparad alerta automático de ESTOQUE_BAIXO
UPDATE public.abastecimento
SET quantidade_atual = 2
WHERE id_compartimento = '40000000-0000-4000-8000-000000000001' AND ativo = true;

-- confere se o alerta gerado automaticamente na tabela alerta
SELECT * FROM public.alerta 
WHERE tipo = 'ESTOQUE_BAIXO' 
ORDER BY data_hora DESC LIMIT 3;

-- 2. bloqueio de edição (RN03): tenta alterar uma dose já concluída e o banco barra com erro esperado
UPDATE public.dispensacao 
SET quantidade_liberada = 99 
WHERE id_dispensacao = '90000000-0000-4000-8000-000000000002';

-- 3. bloqueio de exclusão (RN03): tenta apagar um registro do histórico e o banco barra com erro esperado
DELETE FROM public.dispensacao 
WHERE id_dispensacao = '90000000-0000-4000-8000-000000000002';
