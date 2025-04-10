-- Adição da tabela "Obra" como elemento central
CREATE TABLE obra (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuario(id),
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    endereco TEXT NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Em Planejamento',
    data_inicio_prevista DATE,
    data_fim_prevista DATE,
    data_inicio_real DATE,
    data_fim_real DATE
);

-- Alteração da tabela de solicitações para incluir referência à obra
ALTER TABLE solicitacao ADD COLUMN obra_id INTEGER REFERENCES obra(id);

-- Tabela para vincular profissionais às obras
CREATE TABLE profissional_obra (
    id SERIAL PRIMARY KEY,
    obra_id INTEGER REFERENCES obra(id),
    profissional_id INTEGER REFERENCES profissional(id),
    orcamento_servico_id INTEGER REFERENCES orcamento_servico(id),
    data_inicio DATE,
    data_fim DATE,
    status VARCHAR(50) DEFAULT 'Contratado'
);

-- Tabela para vincular materiais às obras
CREATE TABLE material_obra (
    id SERIAL PRIMARY KEY,
    obra_id INTEGER REFERENCES obra(id),
    orcamento_material_id INTEGER REFERENCES orcamento_material(id),
    data_entrega DATE,
    status VARCHAR(50) DEFAULT 'Aguardando Entrega'
);

-- Alteração da tabela de canais de mensagens para incluir referência à obra
ALTER TABLE canal_mensagem ADD COLUMN obra_id INTEGER REFERENCES obra(id);

-- Função para criar canal de obra automaticamente ao criar uma obra
CREATE OR REPLACE FUNCTION criar_canal_obra()
RETURNS TRIGGER AS $$
DECLARE
    canal_id INTEGER;
BEGIN
    -- Criar um novo canal para a obra
    INSERT INTO canal_mensagem (titulo, obra_id)
    VALUES (
        'Obra: ' || NEW.titulo,
        NEW.id
    )
    RETURNING id INTO canal_id;
    
    -- Adicionar o criador da obra como participante
    INSERT INTO canal_participante (canal_id, usuario_id)
    VALUES (canal_id, NEW.usuario_id);
    
    -- Adicionar uma mensagem automática de sistema
    INSERT INTO mensagem (canal_id, remetente_id, conteudo)
    VALUES (
        canal_id, 
        NEW.usuario_id, 
        'Canal da obra criado. Aqui serão centralizadas as comunicações relacionadas a esta obra.'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para criar canal quando uma obra for criada
CREATE TRIGGER trigger_criar_canal_obra
AFTER INSERT ON obra
FOR EACH ROW
EXECUTE FUNCTION criar_canal_obra();

-- Modificação da função de criar canal quando um orçamento de material é aceito
CREATE OR REPLACE FUNCTION criar_canal_orcamento_material()
RETURNS TRIGGER AS $$
DECLARE
    usuario_solicitante INTEGER;
    usuario_vendedor INTEGER;
    obra_id INTEGER;
    canal_id INTEGER;
BEGIN
    IF NEW.status = 'Aceito' AND OLD.status != 'Aceito' THEN
        -- Obter o usuário solicitante e a obra relacionada
        SELECT s.usuario_id, s.obra_id INTO usuario_solicitante, obra_id
        FROM solicitacao s
        WHERE s.id = NEW.solicitacao_id;
        
        -- Obter o usuário vendedor
        SELECT v.usuario_id INTO usuario_vendedor
        FROM vendedor v
        WHERE v.id = NEW.vendedor_id;
        
        -- Criar um novo canal
        INSERT INTO canal_mensagem (titulo, solicitacao_id, orcamento_material_id, obra_id)
        VALUES (
            'Orçamento de Material - ' || (SELECT titulo FROM solicitacao WHERE id = NEW.solicitacao_id),
            NEW.solicitacao_id,
            NEW.id,
            obra_id
        )
        RETURNING id INTO canal_id;
        
        -- Adicionar o solicitante como participante
        INSERT INTO canal_participante (canal_id, usuario_id)
        VALUES (canal_id, usuario_solicitante);
        
        -- Adicionar o vendedor como participante
        INSERT INTO canal_participante (canal_id, usuario_id)
        VALUES (canal_id, usuario_vendedor);
        
        -- Adicionar uma mensagem automática de sistema
        INSERT INTO mensagem (canal_id, remetente_id, conteudo)
        VALUES (
            canal_id, 
            usuario_solicitante, 
            'Orçamento de material aceito. Este canal foi criado para facilitar a comunicação entre as partes.'
        );
        
        -- Vincular o material à obra
        INSERT INTO material_obra (obra_id, orcamento_material_id)
        VALUES (obra_id, NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Modificação da função de criar canal quando um orçamento de serviço é aceito
CREATE OR REPLACE FUNCTION criar_canal_orcamento_servico()
RETURNS TRIGGER AS $$
DECLARE
    usuario_solicitante INTEGER;
    usuario_profissional INTEGER;
    obra_id INTEGER;
    canal_id INTEGER;
BEGIN
    IF NEW.status = 'Aceito' AND OLD.status != 'Aceito' THEN
        -- Obter o usuário solicitante e a obra relacionada
        SELECT s.usuario_id, s.obra_id INTO usuario_solicitante, obra_id
        FROM solicitacao s
        WHERE s.id = NEW.solicitacao_id;
        
        -- Obter o usuário profissional
        SELECT p.usuario_id INTO usuario_profissional
        FROM profissional p
        WHERE p.id = NEW.profissional_id;
        
        -- Criar um novo canal
        INSERT INTO canal_mensagem (titulo, solicitacao_id, orcamento_servico_id, obra_id)
        VALUES (
            'Orçamento de Serviço - ' || (SELECT titulo FROM solicitacao WHERE id = NEW.solicitacao_id),
            NEW.solicitacao_id,
            NEW.id,
            obra_id
        )
        RETURNING id INTO canal_id;
        
        -- Adicionar o solicitante como participante
        INSERT INTO canal_participante (canal_id, usuario_id)
        VALUES (canal_id, usuario_solicitante);
        
        -- Adicionar o profissional como participante
        INSERT INTO canal_participante (canal_id, usuario_id)
        VALUES (canal_id, usuario_profissional);
        
        -- Adicionar uma mensagem automática de sistema
        INSERT INTO mensagem (canal_id, remetente_id, conteudo)
        VALUES (
            canal_id, 
            usuario_solicitante, 
            'Orçamento de serviço aceito. Este canal foi criado para facilitar a comunicação entre as partes.'
        );
        
        -- Vincular o profissional à obra
        INSERT INTO profissional_obra (obra_id, profissional_id, orcamento_servico_id)
        VALUES (obra_id, NEW.profissional_id, NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar view para visualização de obras com suas solicitações, orçamentos e profissionais
CREATE VIEW vw_obras_completas AS
SELECT 
    o.id AS obra_id,
    o.titulo AS obra_titulo,
    o.descricao AS obra_descricao,
    o.status AS obra_status,
    o.data_inicio_prevista,
    o.data_fim_prevista,
    o.data_inicio_real,
    o.data_fim_real,
    un.nome_completo AS proprietario_nome,
    COUNT(DISTINCT s.id) AS total_solicitacoes,
    COUNT(DISTINCT om.id) AS total_orcamentos_material,
    COUNT(DISTINCT os.id) AS total_orcamentos_servico,
    COUNT(DISTINCT po.id) AS total_profissionais_vinculados,
    COUNT(DISTINCT mo.id) AS total_materiais_aprovados
FROM 
    obra o
JOIN 
    usuario u ON o.usuario_id = u.id
JOIN 
    usuario_normal un ON u.id = un.usuario_id
LEFT JOIN 
    solicitacao s ON o.id = s.obra_id
LEFT JOIN 
    orcamento_material om ON s.id = om.solicitacao_id AND om.status = 'Aceito'
LEFT JOIN 
    orcamento_servico os ON s.id = os.solicitacao_id AND os.status = 'Aceito'
LEFT JOIN 
    profissional_obra po ON o.id = po.obra_id
LEFT JOIN 
    material_obra mo ON o.id = mo.obra_id
GROUP BY 
    o.id, o.titulo, o.descricao, o.status, o.data_inicio_prevista, o.data_fim_prevista, 
    o.data_inicio_real, o.data_fim_real, un.nome_completo
ORDER BY 
    o.data_criacao DESC;

-- Índices para melhorar performance das consultas relacionadas à obra
CREATE INDEX idx_solicitacao_obra ON solicitacao(obra_id);
CREATE INDEX idx_profissional_obra_obra ON profissional_obra(obra_id);
CREATE INDEX idx_profissional_obra_prof ON profissional_obra(profissional_id);
CREATE INDEX idx_material_obra_obra ON material_obra(obra_id);
CREATE INDEX idx_material_obra_orcamento ON material_obra(orcamento_material_id);
CREATE INDEX idx_canal_obra ON canal_mensagem(obra_id);
CREATE INDEX idx_obra_usuario ON obra(usuario_id);
CREATE INDEX idx_obra_status ON obra(status);
