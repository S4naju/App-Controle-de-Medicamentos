import { useState, useEffect } from "react";
import "./App.css";

function Icon({ name, size = 20 }) {
  return (
    <span
      className="material-symbols-outlined"
      style={{ fontSize: `${size}px`, lineHeight: 1, verticalAlign: "middle" }}
    >
      {name}
    </span>
  );
}

const initialMedicines = [
  {
    id: 1,
    name: "Losartana",
    dose: "50 mg",
    time: "14:00",
    openedAt: new Date().toISOString().slice(0, 10),
    storageDays: 2
  },
  {
    id: 2,
    name: "Vitamina D",
    dose: "1 cápsula",
    time: "20:00",
    openedAt: new Date().toISOString().slice(0, 10),
    storageDays: 2
  }
];

function App() {
  useEffect(() => {
    const linkId = "google-material-symbols";
    if (!document.getElementById(linkId)) {
      const link = document.createElement("link");
      link.id = linkId;
      link.rel = "stylesheet";
      link.href =
        "https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0";
      document.head.appendChild(link);
    }
  }, []);

  const [activePage, setActivePage] = useState("dashboard");
  const [medicines, setMedicines] = useState(initialMedicines);
  const [showForm, setShowForm] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [toastMessage, setToastMessage] = useState("");

  const [form, setForm] = useState({
    name: "",
    dose: "",
    time: "",
    openedAt: new Date().toISOString().slice(0, 10),
    storageDays: 2
  });

  const [history, setHistory] = useState([
    {
      id: 1,
      medicine: "Losartana",
      dose: "50 mg",
      time: "08:00",
      status: "Retirada confirmada"
    }
  ]);

  function showToast(msg) {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(""), 3000);
  }

  function getStorageStatus(medicine) {
    const start = new Date(medicine.openedAt + "T00:00:00");
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const elapsed = Math.floor((today - start) / (1000 * 60 * 60 * 24));

    if (elapsed >= medicine.storageDays) return "expired";
    if (elapsed === medicine.storageDays - 1) return "warning";

    return "safe";
  }

  function addMedicine(e) {
    e.preventDefault();

    const newMedicine = {
      ...form,
      id: Date.now(),
      storageDays: Number(form.storageDays)
    };

    setMedicines([...medicines, newMedicine]);

    setForm({
      name: "",
      dose: "",
      time: "",
      openedAt: new Date().toISOString().slice(0, 10),
      storageDays: 2
    });

    setShowForm(false);
    showToast(`${newMedicine.name} cadastrado com sucesso!`);
  }

  function removeMedicine(id, name) {
    setMedicines(medicines.filter(m => m.id !== id));
    showToast(`${name} removido.`);
  }

  function confirmDose(medicine) {
    setHistory([
      {
        id: Date.now(),
        medicine: medicine.name,
        dose: medicine.dose,
        time: new Date().toLocaleTimeString("pt-BR", {
          hour: "2-digit",
          minute: "2-digit"
        }),
        status: "Retirada confirmada"
      },
      ...history
    ]);
    showToast(`Retirada de ${medicine.name} registrada no histórico!`);
  }

  const alerts = medicines.filter(m => getStorageStatus(m) !== "safe");

  // Ordena por horário para destacar a próxima dose
  const sortedMedicines = [...medicines].sort((a, b) =>
    a.time.localeCompare(b.time)
  );
  const nextMedicine = sortedMedicines[0];

  const filteredMedicines = sortedMedicines.filter(m =>
    m.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="app">
      {toastMessage && (
        <div className="toast">
          <Icon name="check_circle" size={18} />
          <span>{toastMessage}</span>
        </div>
      )}

      <aside className="sidebar">
        <div className="brand">
          <div className="brand-icon">
            <Icon name="heart_plus" size={26}/>
          </div>
          <div>
            <h2>Care Sync</h2>
            <span>Smart Dispenser</span>
          </div>
        </div>

        <div className="menu-label">NAVEGAÇÃO</div>

        <nav>
          <button
            className={activePage === "dashboard" ? "active" : ""}
            onClick={() => setActivePage("dashboard")}
          >
            <Icon name="dashboard" size={20} />
            Visão Geral
          </button>

          <button
            className={activePage === "medicines" ? "active" : ""}
            onClick={() => setActivePage("medicines")}
          >
            <Icon name="medication" size={20} />
            Medicamentos
            <span className="nav-badge">{medicines.length}</span>
          </button>

          <button
            className={activePage === "history" ? "active" : ""}
            onClick={() => setActivePage("history")}
          >
            <Icon name="history" size={20} />
            Histórico
          </button>

          <button
            className={activePage === "device" ? "active" : ""}
            onClick={() => setActivePage("device")}
          >
            <Icon name="memory" size={20} />
            Dispositivo ESP32
          </button>
        </nav>

        <div className="sidebar-bottom">
          <div className="user-avatar">
            <Icon name="person" size={20} />
          </div>
          <div className="user-info">
            <strong>Responsável</strong>
            <span>Cuidador Principal</span>
          </div>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <span className="welcome">Painel de Monitoramento</span>
            <h2>
              {activePage === "dashboard" && "Visão Geral"}
              {activePage === "medicines" && "Meus Medicamentos"}
              {activePage === "history" && "Histórico de Doses"}
              {activePage === "device" && "Status do Dispensador"}
            </h2>
          </div>

          <div className="topbar-right">
            <div className="connection">
              <span className="online-dot"></span>
              Dispositivo Online
            </div>
            <div className="date-pill">
              <Icon name="calendar_today" size={15} />
              {new Date().toLocaleDateString("pt-BR")}
            </div>
          </div>
        </header>

        {activePage === "dashboard" && (
          <section className="content">
            {nextMedicine && (
              <div className="hero-card">
                <div className="hero-info">
                  <span className="hero-tag">
                    <Icon name="schedule" size={15} /> PRÓXIMA DOSE PROGRAMADA
                  </span>
                  <h3>
                    {nextMedicine.name} <span>• {nextMedicine.dose}</span>
                  </h3>
                  <p>
                    Horário previsto para liberação no compartimento:{" "}
                    <strong>{nextMedicine.time}</strong>
                  </p>
                </div>
                <button
                  className="hero-button"
                  onClick={() => confirmDose(nextMedicine)}
                >
                  <Icon name="check_circle" size={19} />
                  Confirmar Retirada
                </button>
              </div>
            )}

            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-icon primary">
                  <Icon name="medication" size={24} />
                </div>
                <div>
                  <span>Medicamentos Ativos</span>
                  <h2>{medicines.length}</h2>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon cyan">
                  <Icon name="check_circle" size={24} />
                </div>
                <div>
                  <span>Doses Confirmadas</span>
                  <h2>{history.length}</h2>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon amber">
                  <Icon name="notifications_active" size={24} />
                </div>
                <div>
                  <span>Alertas de Validade</span>
                  <h2>{alerts.length}</h2>
                </div>
              </div>
            </div>

            <div className="dashboard-columns">
              <div className="column-main">
                <div className="section-title">
                  <h3>
                    <Icon name="schedule" size={20} /> Cronograma de Hoje
                  </h3>
                  <button
                    className="text-button"
                    onClick={() => setActivePage("medicines")}
                  >
                    Gerenciar todos →
                  </button>
                </div>

                <div className="medicine-list">
                  {sortedMedicines.map(medicine => (
                    <div className="medicine-row" key={medicine.id}>
                      <div className="medicine-icon">
                        <Icon name="medication" size={21} />
                      </div>
                      <div className="medicine-details">
                        <strong>{medicine.name}</strong>
                        <span>{medicine.dose}</span>
                      </div>
                      <div className="medicine-time">
                        <Icon name="schedule" size={15} />
                        {medicine.time}
                      </div>
                    </div>
                  ))}

                  {medicines.length === 0 && (
                    <p className="empty">Nenhum medicamento cadastrado.</p>
                  )}
                </div>
              </div>

              <div className="column-side">
                <div className="section-title">
                  <h3>
                    <Icon name="notifications" size={20} /> Avisos e Segurança
                  </h3>
                </div>

                <div className="alert-box sun-alert">
                  <Icon name="light_mode" size={22} />
                  <div>
                    <strong>Proteção Térmica e Solar</strong>
                    <p>
                      Mantenha o dispensador longe da luz solar direta e umidade.
                    </p>
                  </div>
                </div>

                {alerts.map(medicine => (
                  <div
                    className={`alert-box ${
                      getStorageStatus(medicine) === "expired"
                        ? "danger-alert"
                        : "warning-alert"
                    }`}
                    key={medicine.id}
                  >
                    <Icon name="warning" size={22} />
                    <div>
                      <strong>
                        {getStorageStatus(medicine) === "expired"
                          ? `Prazo atingido: ${medicine.name}`
                          : `Atenção: ${medicine.name}`}
                      </strong>
                      <p>
                        {getStorageStatus(medicine) === "expired"
                          ? "Verifique o compartimento. Prazo fora do blister excedido."
                          : "Próximo do limite configurado fora da embalagem original."}
                      </p>
                    </div>
                  </div>
                ))}

                <div className="late-notice">
                  <Icon name="info" size={20} />
                  <div>
                    <strong>Tolerância de 30 minutos</strong>
                    <p>
                      Alertas críticos são disparados se a retirada não for
                      detectada pelo sensor óptico em até 30 min.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>
        )}

        {activePage === "medicines" && (
          <section className="content">
            <div className="page-intro">
              <div>
                <h3>Gerenciamento de Medicamentos</h3>
                <p>Adicione horários e controle o tempo fora da embalagem.</p>
              </div>

              <button
                className="primary-button"
                onClick={() => setShowForm(!showForm)}
              >
                <Icon name={showForm ? "close" : "add"} size={19} />
                {showForm ? "Fechar formulário" : "Novo medicamento"}
              </button>
            </div>

            {showForm && (
              <form className="form-card" onSubmit={addMedicine}>
                <h3>Cadastrar Novo Medicamento</h3>

                <div className="form-grid">
                  <label>
                    Nome do medicamento
                    <input
                      required
                      placeholder="Ex: Losartana"
                      value={form.name}
                      onChange={e => setForm({ ...form, name: e.target.value })}
                    />
                  </label>

                  <label>
                    Dosagem
                    <input
                      required
                      placeholder="Ex: 50 mg"
                      value={form.dose}
                      onChange={e => setForm({ ...form, dose: e.target.value })}
                    />
                  </label>

                  <label>
                    Horário da dose
                    <input
                      type="time"
                      required
                      value={form.time}
                      onChange={e => setForm({ ...form, time: e.target.value })}
                    />
                  </label>

                  <label>
                    Data de abertura do blister
                    <input
                      type="date"
                      required
                      value={form.openedAt}
                      onChange={e =>
                        setForm({ ...form, openedAt: e.target.value })
                      }
                    />
                  </label>

                  <label>
                    Validade no dispensador (dias)
                    <input
                      type="number"
                      min="1"
                      required
                      value={form.storageDays}
                      onChange={e =>
                        setForm({ ...form, storageDays: e.target.value })
                      }
                    />
                  </label>
                </div>

                <div className="form-actions">
                  <button
                    type="button"
                    className="cancel-button"
                    onClick={() => setShowForm(false)}
                  >
                    Cancelar
                  </button>
                  <button type="submit" className="primary-button">
                    Salvar medicamento
                  </button>
                </div>
              </form>
            )}

            <div className="search-bar">
              <Icon name="search" size={20} />
              <input
                type="text"
                placeholder="Buscar medicamento cadastrado..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="medicine-cards-grid">
              {filteredMedicines.map(medicine => {
                const status = getStorageStatus(medicine);

                return (
                  <div className="medicine-card" key={medicine.id}>
                    <div className="medicine-card-top">
                      <div className="medicine-icon">
                        <Icon name="medication" size={24} />
                      </div>
                      <span
                        className={`status ${
                          status === "safe"
                            ? "status-safe"
                            : status === "warning"
                            ? "status-warning"
                            : "status-danger"
                        }`}
                      >
                        {status === "safe"
                          ? "Dentro do prazo"
                          : status === "warning"
                          ? "Prazo próximo"
                          : "Prazo atingido"}
                      </span>
                    </div>

                    <div className="medicine-details">
                      <strong>{medicine.name}</strong>
                      <span className="dose-badge">
                        {medicine.dose} • às {medicine.time}
                      </span>
                      <span className="storage-info">
                        Abertura: {medicine.openedAt} ({medicine.storageDays}{" "}
                        dias)
                      </span>
                    </div>

                    <div className="medicine-card-footer">
                      <button
                        className="confirm-pill-btn"
                        onClick={() => confirmDose(medicine)}
                      >
                        <Icon name="check_circle" size={17} />
                        Confirmar dose
                      </button>

                      <button
                        className="icon-button"
                        title="Remover medicamento"
                        onClick={() =>
                          removeMedicine(medicine.id, medicine.name)
                        }
                      >
                        <Icon name="delete" size={19} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {activePage === "history" && (
          <section className="content">
            <div className="page-intro">
              <div>
                <h3>Histórico de Administração</h3>
                <p>Registros de doses confirmadas pelo sistema e sensores.</p>
              </div>
            </div>

            <div className="history-card">
              {history.map(item => (
                <div className="history-row" key={item.id}>
                  <div className="history-icon">
                    <Icon name="check_circle" size={22} />
                  </div>
                  <div className="medicine-details">
                    <strong>{item.medicine}</strong>
                    <span>
                      {item.dose ? `${item.dose} • ` : ""}Registrado às{" "}
                      {item.time}
                    </span>
                  </div>
                  <span className="status status-safe">{item.status}</span>
                </div>
              ))}

              {history.length === 0 && (
                <p className="empty">Nenhum registro disponível.</p>
              )}
            </div>
          </section>
        )}

        {activePage === "device" && (
          <section className="content">
            <div className="page-intro">
              <div>
                <h3>Monitoramento do Hardware</h3>
                <p>Telemetria e status dos módulos do dispensador físico.</p>
              </div>
            </div>

            <div className="device-card">
              <div className="device-heading">
                <div className="device-icon">
                  <Icon name="memory" size={30} />
                </div>
                <div>
                  <h3>Dispensador Care Sync</h3>
                  <span>Controlador ESP32 • Protocolo MQTT</span>
                </div>
                <span className="status status-safe">Modo Demonstração</span>
              </div>

              <div className="device-status-grid">
                <div className="hw-item">
                  <Icon name="wifi" size={22} />
                  <div>
                    <strong>Conexão Wi-Fi / Broker</strong>
                    <span>Pronto para integração</span>
                  </div>
                </div>
                <div className="hw-item">
                  <Icon name="verified_user" size={22} />
                  <div>
                    <strong>Leitor RFID</strong>
                    <span>Aguardando tag do paciente</span>
                  </div>
                </div>
                <div className="hw-item">
                  <Icon name="inventory_2" size={22} />
                  <div>
                    <strong>Sensor Óptico de Queda</strong>
                    <span>Aguardando leitura física</span>
                  </div>
                </div>
                <div className="hw-item">
                  <Icon name="notifications_active" size={22} />
                  <div>
                    <strong>Alarme Sonoro e LED</strong>
                    <span>Em espera</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="late-notice">
              <Icon name="cloud_sync" size={22} />
              <div>
                <strong>Arquitetura de Integração</strong>
                <p>
                  Os dados deste painel serão sincronizados em tempo real com o
                  banco PostgreSQL via API e broker MQTT na próxima etapa.
                </p>
              </div>
            </div>
          </section>
        )}

        <footer>
          Care Sync © 2026 • Sistema Inteligente de Controle de Medicação
        </footer>
      </main>
    </div>
  );
}

export default App;