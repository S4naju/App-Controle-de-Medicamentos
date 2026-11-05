
import "./MedicamentoCard.css";

function MedicamentoCard({ medicamento, onEditar, onExcluir, onReporDose }) {
    const porcentagem = Math.min(
        (medicamento.tempoFora / 48) * 100,
        100
    );

    const tempoRestante = Math.max(48 - medicamento.tempoFora, 0);

    const seguro = medicamento.tempoFora < 48;

    return (
        <div className={`medicamento-card ${seguro ? "" : "vencido"}`}>

            <div className="medicamento-topo">
                <div className="medicamento-informacoes">
                    <div className="medicamento-tags">
                        <span className="tag-gaveta">
                            Gaveta #{medicamento.gaveta}
                        </span>

                        <span className="tag-dose">
                            {medicamento.dose}
                        </span>

                        <span className="tag-categoria">
                            {medicamento.categoria}
                        </span>
                    </div>

                    <h3>
                        {medicamento.nome} 
                        <span> ({medicamento.concentracao})</span>
                    </h3>

                    <p className="medico">
                        Prescrito por: {medicamento.medico}
                    </p>
                </div>

                <div className="horario">
                    <h2>◷ {medicamento.horario}</h2>
                    <span>Disparo do Buzzer & LED</span>
                </div>
            </div>

            <div className="observacao">
                "{medicamento.observacao}"
            </div>

            <div className="armazenamento">
                <div className="armazenamento-info">
                    <strong>Tempo fora da embalagem lacrada:</strong>

                    <strong>
                        {medicamento.tempoFora}h de 48h
                        ({tempoRestante.toFixed(1)}h restantes)
                    </strong>
                </div>

                <div className="barra-fundo">
                    <div
                        className="barra-progresso"
                        style={{ width: `${porcentagem}%` }}
                    ></div>
                </div>

                <div className="armazenamento-status">
                    <span className={seguro ? "status-seguro" : "status-alerta"}>
                        {seguro ? "SEGURO NO DISPENSADOR" : "VERIFICAR ARMAZENAMENTO"}
                    </span>

                    <span>
                        Abastecido em: {medicamento.abastecidoEm}
                    </span>
                </div>
            </div>

            <div className="medicamento-acoes">
                <button
                    className="btn-repor"
                    onClick={() => onReporDose(medicamento.id)}
                >
                    ↻ Repor Dose (Zerar 48h)
                </button>

                <div>
                    <button
                        className="btn-editar"
                        onClick={() => onEditar(medicamento)}
                    >
                        ✏️ Editar
                    </button>

                    <button
                        className="btn-excluir"
                        onClick={() => onExcluir(medicamento.id)}
                    >
                        🗑 Excluir
                    </button>
                </div>
            </div>

        </div>
    );
}

export default MedicamentoCard;
