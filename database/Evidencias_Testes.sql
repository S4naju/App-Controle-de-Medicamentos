-- FUNCTIONS (Paciente 01, Abastecimento 01, Tratamento 01)
SELECT 
    public.fn_verificar_disponibilidade_dose('80000000-0000-4000-8000-000000000001') AS dose_disponivel,
    public.fn_calcular_taxa_adesao('20000000-0000-4000-8000-000000000001', 30) AS taxa_adesao_pct,
    public.fn_dias_autonomia_abastecimento('70000000-0000-4000-8000-000000000001') AS dias_autonomia;


--- PROCEDURES
-- Teste da Procedure sp_registrar_dispensacao (Dispensação 06 está PROGRAMADA no seed)
CALL public.sp_registrar_dispensacao(
    '90000000-0000-4000-8000-000000000006',
    'EVT-TESTE-APD2-001'
);

-- Conferir alteração de status para LIBERADA e baixa no abastecimento 06:
SELECT id_dispensacao, status, quantidade_liberada, data_hora_liberacao, prazo_retirada
FROM public.dispensacao
WHERE id_dispensacao = '90000000-0000-4000-8000-000000000006';

-- Teste da Procedure sp_confirmar_retirada_sensor (Dispensação 01 está LIBERADA no seed)
CALL public.sp_confirmar_retirada_sensor('90000000-0000-4000-8000-000000000001');

-- Conferir retirada confirmada e novo agendamento PROGRAMADA gerado:
SELECT id_dispensacao, status, data_hora_programada, data_hora_retirada, retirada_confirmada_sensor
FROM public.dispensacao
WHERE id_tratamento = '80000000-0000-4000-8000-000000000001'
ORDER BY data_hora_programada DESC;

-- Teste da Procedure sp_reabastecer_compartimento (Compartimento 01)
CALL public.sp_reabastecer_compartimento(
    '10000000-0000-4000-8000-000000000001',
    '60000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000001',
    30,
    now() + interval '90 days'
);

SELECT id_abastecimento, quantidade_inicial, quantidade_atual, ativo
FROM public.abastecimento
WHERE id_compartimento = '40000000-0000-4000-8000-000000000001';


--TRIGGERS
-- Teste do Trigger tg_alerta_estoque_baixo
UPDATE public.abastecimento
SET quantidade_atual = 2
WHERE id_compartimento = '40000000-0000-4000-8000-000000000001' AND ativo = true;

SELECT * FROM public.alerta 
WHERE tipo = 'ESTOQUE_BAIXO' 
ORDER BY data_hora DESC LIMIT 3;

-- Teste de Bloqueio dos Triggers (RN01 e RN03 - devem gerar ERRO esperado)
-- Tentativa de alterar registro histórico RETIRADA (RN03):
UPDATE public.dispensacao 
SET quantidade_liberada = 99 
WHERE id_dispensacao = '90000000-0000-4000-8000-000000000002';

-- Tentativa de deletar histórico de dispensação (RN03):
DELETE FROM public.dispensacao 
WHERE id_dispensacao = '90000000-0000-4000-8000-000000000002';