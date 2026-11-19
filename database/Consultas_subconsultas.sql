--CONSULTAS SIMPLES
-- 1. listar pacientes cadastrados em ordem alfabetica
SELECT id_paciente, nome, data_nascimento, data_cadastro
FROM public.paciente
ORDER BY nome;

-- 2. buscar medicamentos que contenham 'met' no nome
SELECT id_medicamento, nome, dosagem, instrucoes_armazenamento
FROM public.medicamento
WHERE nome ILIKE '%met%' -- buscar em qualquer posição %
ORDER BY nome;

-- 3. listar dispositivos que estao offline
SELECT numero_serie, status_conexao, ultimo_contato
FROM public.dispositivo
WHERE status_conexao = 'OFFLINE'
ORDER BY ultimo_contato;

-- 4. consultar abastecimentos com estoque atual igual ou inferior a 12 unidades
SELECT id_abastecimento, quantidade_inicial, quantidade_atual, data_abastecimento
FROM public.abastecimento
WHERE ativo = true AND quantidade_atual <= 12
ORDER BY quantidade_atual ASC; -- menor pro maior

-- 5. consultar dispensacoes que ainda nao foram retiradas
SELECT id_dispensacao, data_hora_programada, data_hora_liberacao, prazo_retirada, status
FROM public.dispensacao
WHERE status IN ('PROGRAMADA', 'LIBERADA', 'ATRASADA')
ORDER BY data_hora_programada DESC;


--CONSULTAS JOINS
-- 6. quantidade de medicamentos cadastrados por paciente
SELECT p.id_paciente, p.nome AS paciente,
       COUNT(m.id_medicamento) AS total_medicamentos
FROM public.paciente p
LEFT JOIN public.medicamento m ON m.id_paciente = p.id_paciente
GROUP BY p.id_paciente, p.nome
HAVING COUNT(m.id_medicamento) >= 1 -- so mostra pacientes que tem pelos menos um remédio cadastrado
ORDER BY total_medicamentos DESC, p.nome;

-- 7. histórico de dispensações por paciente e status
SELECT p.nome AS paciente, d.status,
       COUNT(d.id_dispensacao) AS total_dispensacoes,
       SUM(d.quantidade_liberada) AS unidades_liberadas
FROM public.paciente p
JOIN public.medicamento m ON m.id_paciente = p.id_paciente
JOIN public.tratamento t ON t.id_medicamento = m.id_medicamento
JOIN public.dispensacao d ON d.id_tratamento = t.id_tratamento
GROUP BY p.nome, d.status
HAVING COUNT(d.id_dispensacao) >= 1
ORDER BY p.nome, total_dispensacoes DESC;

-- 8. Estoque atual por paciente e medicamento, destacando estoque baixo.
SELECT p.nome AS paciente, m.nome AS medicamento,
       SUM(a.quantidade_atual) AS estoque_atual,
       SUM(a.quantidade_inicial) AS estoque_inicial
FROM public.paciente p
JOIN public.medicamento m ON m.id_paciente = p.id_paciente
JOIN public.abastecimento a ON a.id_medicamento = m.id_medicamento
WHERE a.ativo = true
GROUP BY p.nome, m.nome
HAVING SUM(a.quantidade_atual) <= 15 -- se tiver <= de 15 unidades ele alerta para restocar 
ORDER BY estoque_atual ASC;


--SUBCONSULTAS: IN, ALL, EXISTS E ANY
-- 9. listar pacientes que possuem pelo menos um medicamento cadastrado no sistema - IN
SELECT id_paciente, nome
FROM public.paciente
WHERE id_paciente IN (
    SELECT m.id_paciente
    FROM public.medicamento m
)
ORDER BY nome;

-- 10. listar medicamentos cujo estoque atual é maior que todos (ALL) os estoques com saldo < 10
SELECT m.id_medicamento, m.nome, a.quantidade_atual
FROM public.medicamento m
JOIN public.abastecimento a ON a.id_medicamento = m.id_medicamento
WHERE a.quantidade_atual > ALL (
    SELECT a2.quantidade_atual
    FROM public.abastecimento a2
    WHERE a2.quantidade_atual < 10
)
ORDER BY a.quantidade_atual DESC;

-- 11. identificar usuários que possuem pelo menos um alerta do tipo ESTOQUE_BAIXO - EXISTS
SELECT u.id_usuario, u.nome
FROM public.usuario u
WHERE EXISTS (
    SELECT 1
    FROM public.alerta al
    WHERE al.id_usuario = u.id_usuario
      AND al.tipo = 'ESTOQUE_BAIXO'
)
ORDER BY u.nome;

-- 12. listar medicamentos cuja quantidade atual seja maior que pelo menos um (ANY) estoque ativo registrado
SELECT m.nome, a.quantidade_atual
FROM public.medicamento m
JOIN public.abastecimento a ON a.id_medicamento = m.id_medicamento
WHERE a.quantidade_atual > ANY (
    SELECT a2.quantidade_atual
    FROM public.abastecimento a2
    WHERE a2.ativo = true
)
ORDER BY a.quantidade_atual DESC;
