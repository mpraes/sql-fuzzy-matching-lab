SELECT 
    -- Dados da Empresa A
    A.id_golden AS id_a,
    A.nome_original AS original_a,       -- Nome como veio (com LTDA, ME)
    A.nome_padronizado AS limpo_a,       -- Nome que o robô usou
    
    -- Dados da Empresa B
    B.id_golden AS id_b,
    B.nome_original AS original_b,       -- Nome como veio (com erro, ponto)
    B.nome_padronizado AS limpo_b,       -- Nome que o robô usou
    
    -- O Score que deu 100%
    V.score
    
FROM vw_relatorio_duplicatas V
JOIN tb_empresas_golden A ON V.id_a = A.id_golden
JOIN tb_empresas_golden B ON V.id_b = B.id_golden

WHERE V.score >= 0.99 -- Vamos focar só nesses casos "idênticos"
ORDER BY random()
limit 20;