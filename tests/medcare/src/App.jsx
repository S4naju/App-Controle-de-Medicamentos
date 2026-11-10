
import { useState } from "react";
import {
  LayoutDashboard, Pill, History, Cpu, Plus,
  Clock, CheckCircle2, AlertTriangle, Sun,
  Wifi, WifiOff, Bell, UserRound, CalendarDays,
  Trash2, HeartPulse, ShieldCheck, PackageOpen
} from "lucide-react";
import "./App.css";

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
  const [activePage, setActivePage] = useState("dashboard");
  const [medicines, setMedicines] = useState(initialMedicines);
  const [showForm, setShowForm] = useState(false);

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
      time: "08:00",
      status: "Retirada confirmada"
    }
  ]);

  function getStorageStatus(medicine) {
    const start = new Date(medicine.openedAt + "T00:00:00");
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const elapsed = Math.floor(
      (today - start) / (1000 * 60 * 60 * 24)
    );

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
  }

  function removeMedicine(id) {
    setMedicines(medicines.filter(m => m.id !== id));
  }

  function confirmDose(medicine) {
    setHistory([
      {
        id: Date.now(),
        medicine: medicine.name,
        time: new Date().toLocaleTimeString("pt-BR", {
          hour: "2-digit",
          minute: "2-digit"
        }),
        status: "Retirada confirmada"
      },
      ...history
    ]);
  }

  const alerts = medicines.filter(
    m => getStorageStatus(m) !== "safe"
  );

  return (
    <div className="app">

      <aside className="sidebar">
        <div className="brand">
          <div className="brand-icon">
            <HeartPulse size={27} />
          </div>
          <div>
            <h2>MedCare</h2>
            <span>Controle de medicação</span>
          </div>
        </div>

        <div className="menu-label">MENU PRINCIPAL</div>

        <nav>
          <button
            className={activePage === "dashboard" ? "active" : ""}
            onClick={() => setActivePage("dashboard")}
          >
            <LayoutDashboard size={20} />
            Dashboard
          </button>

          <button
            className={activePage === "medicines" ? "active" : ""}
            onClick={() => setActivePage("medicines")}
          >
            <Pill size={20} />
            Medicamentos
          </button>

          <button
            className={activePage === "history" ? "active" : ""}
            onClick={() => setActivePage("history")}
          >
            <History size={20} />
            Histórico
          </button>

          <button
            className={activePage === "device" ? "active" : ""}
            onClick={() => setActivePage("device")}
          >
            <Cpu size={20} />
            Dispositivo
          </button>
        </nav>

        <div className="sidebar-bottom">
          <div className="user-avatar">
            <UserRound size={22} />
          </div>
          <div className="user-info">
            <strong>Responsável</strong>
            <span>Monitoramento</span>
          </div>
        </div>
      </aside>

      <main className="main">

        <header className="topbar">
          <div>
            <span className="welcome">Sistema de acompanhamento</span>
            <h2>
              {activePage === "dashboard" && "Visão geral"}
              {activePage === "medicines" && "Medicamentos"}
              {activePage === "history" && "Histórico de doses"}
              {activePage === "device" && "Monitoramento do dispositivo"}
            </h2>
          </div>

          <div className="topbar-right">
            <div className="connection">
              <span className="online-dot"></span>
              Sistema conectado
            </div>
            <div className="profile-icon">
              <UserRound size={21} />
            </div>
          </div>
        </header>

        {activePage === "dashboard" && (
          <section className="content">

            <div className="page-intro">
              <div>
                <h3>Olá! Bem-vindo ao MedCare.</h3>
                <p>Acompanhe os medicamentos e o funcionamento do dispositivo.</p>
              </div>
              <span className="date-label">
                <CalendarDays size={17} />
                {new Date().toLocaleDateString("pt-BR")}
              </span>
            </div>

            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-icon green">
                  <Pill />
                </div>
                <div>
                  <span>Medicamentos cadastrados</span>
                  <h2>{medicines.length}</h2>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon blue">
                  <Clock />
                </div>
                <div>
                  <span>Horários programados</span>
                  <h2>{medicines.length}</h2>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon orange">
                  <Bell />
                </div>
                <div>
                  <span>Alertas de armazenamento</span>
                  <h2>{alerts.length}</h2>
                </div>
              </div>
            </div>

            <div className="alerts-section">
              <div className="section-title">
                <h3><Bell size={20} /> Avisos importantes</h3>
              </div>

              <div className="alert-box sun-alert">
                <Sun size={23} />
                <div>
                  <strong>Proteja os medicamentos da luz solar</strong>
                  <p>Mantenha o dispensador em local protegido do sol e de fontes de calor.</p>
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
                  <AlertTriangle size={23} />
                  <div>
                    <strong>
                      {getStorageStatus(medicine) === "expired"
                        ? `Verifique o prazo de ${medicine.name}`
                        : `Atenção ao armazenamento de ${medicine.name}`}
                    </strong>
                    <p>
                      {getStorageStatus(medicine) === "expired"
                        ? "O prazo configurado foi atingido. Consulte as orientações do medicamento."
                        : "O medicamento está próximo de atingir o prazo configurado fora da embalagem original."}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <div className="section-title medicine-title">
              <h3><Clock size={20} /> Próximos horários</h3>
              <button
                className="text-button"
                onClick={() => setActivePage("medicines")}
              >
                Ver todos
              </button>
            </div>

            <div className="medicine-list">
              {medicines.map(medicine => (
                <div className="medicine-row" key={medicine.id}>
                  <div className="medicine-icon">
                    <Pill size={22} />
                  </div>
                  <div className="medicine-details">
                    <strong>{medicine.name}</strong>
                    <span>{medicine.dose}</span>
                  </div>
                  <div className="medicine-time">
                    <Clock size={16} />
                    {medicine.time}
                  </div>
                </div>
              ))}

              {medicines.length === 0 && (
                <p className="empty">Nenhum medicamento cadastrado.</p>
              )}
            </div>

            <div className="late-notice">
              <AlertTriangle size={21} />
              <div>
                <strong>Monitoramento de doses atrasadas</strong>
                <p>
                  Caso a retirada não seja confirmada em até 30 minutos
                  após o horário programado, o sistema deverá gerar
                  um alerta crítico ao responsável.
                </p>
              </div>
            </div>

          </section>
        )}

        {activePage === "medicines" && (
          <section className="content">

            <div className="page-intro">
              <div>
                <h3>Gerenciamento de medicamentos</h3>
                <p>Cadastre os medicamentos e configure seus horários.</p>
              </div>

              <button
                className="primary-button"
                onClick={() => setShowForm(!showForm)}
              >
                <Plus size={19} />
                Novo medicamento
              </button>
            </div>

            {showForm && (
              <form className="form-card" onSubmit={addMedicine}>
                <h3>Cadastrar medicamento</h3>

                <div className="form-grid">
                  <label>
                    Nome do medicamento
                    <input
                      required
                      placeholder="Ex: Losartana"
                      value={form.name}
                      onChange={e => setForm({...form, name: e.target.value})}
                    />
                  </label>

                  <label>
                    Dosagem
                    <input
                      required
                      placeholder="Ex: 50 mg"
                      value={form.dose}
                      onChange={e => setForm({...form, dose: e.target.value})}
                    />
                  </label>

                  <label>
                    Horário da dose
                    <input
                      type="time"
                      required
                      value={form.time}
                      onChange={e => setForm({...form, time: e.target.value})}
                    />
                  </label>

                  <label>
                    Data de abertura da embalagem
                    <input
                      type="date"
                      required
                      value={form.openedAt}
                      onChange={e => setForm({...form, openedAt: e.target.value})}
                    />
                  </label>

                  <label>
                    Prazo configurado fora da embalagem (dias)
                    <input
                      type="number"
                      min="1"
                      required
                      value={form.storageDays}
                      onChange={e => setForm({...form, storageDays: e.target.value})}
                    />
                  </label>
                </div>

                <p className="form-hint">
                  Configure o prazo conforme a orientação específica do medicamento.
                </p>

                <div className="form-actions">
                  <button type="button" className="cancel-button"
                    onClick={() => setShowForm(false)}>
                    Cancelar
                  </button>
                  <button type="submit" className="primary-button">
                    Salvar medicamento
                  </button>
                </div>
              </form>
            )}

            <div className="medicine-list">
              {medicines.map(medicine => {
                const status = getStorageStatus(medicine);

                return (
                  <div className="medicine-card" key={medicine.id}>
                    <div className="medicine-icon">
                      <Pill size={25} />
                    </div>

                    <div className="medicine-details">
                      <strong>{medicine.name}</strong>
                      <span>{medicine.dose} • {medicine.time}</span>
                      <span className="storage-info">
                        Abertura: {medicine.openedAt}
                      </span>
                      <span className="storage-info">
                        Prazo configurado: {medicine.storageDays} dias
                      </span>
                    </div>

                    <div className="medicine-actions">
                      <span className={`status ${
                        status === "safe" ? "status-safe" :
                        status === "warning" ? "status-warning" :
                        "status-danger"
                      }`}>
                        {status === "safe" ? "Dentro do prazo" :
                         status === "warning" ? "Prazo próximo" :
                         "Prazo atingido"}
                      </span>

                      <button
                        className="icon-button"
                        title="Remover medicamento"
                        onClick={() => removeMedicine(medicine.id)}
                      >
                        <Trash2 size={18} />
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
                <h3>Histórico de administração</h3>
                <p>Acompanhe os registros de retirada dos medicamentos.</p>
              </div>
            </div>

            <div className="history-card">
              {history.map(item => (
                <div className="history-row" key={item.id}>
                  <div className="history-icon">
                    <CheckCircle2 size={22} />
                  </div>
                  <div className="medicine-details">
                    <strong>{item.medicine}</strong>
                    <span>{item.time}</span>
                  </div>
                  <span className="status status-safe">
                    {item.status}
                  </span>
                </div>
              ))}

              {history.length === 0 && (
                <p className="empty">Nenhum registro disponível.</p>
              )}
            </div>

            <p className="form-hint">
              Os registros definitivos deverão ser gerados pelo sistema
              após a confirmação da retirada pelo sensor óptico.
            </p>
          </section>
        )}

        {activePage === "device" && (
          <section className="content">
            <div className="page-intro">
              <div>
                <h3>Monitoramento do dispositivo</h3>
                <p>Informações sobre o dispensador físico.</p>
              </div>
            </div>

            <div className="device-card">
              <div className="device-heading">
                <div className="device-icon">
                  <Cpu size={32} />
                </div>
                <div>
                  <h3>Dispensador MedCare</h3>
                  <span>Microcontrolador ESP32</span>
                </div>
                <span className="status status-safe">
                  Demonstração
                </span>
              </div>

              <div className="device-status-grid">
                <div>
                  <Wifi size={23} />
                  <strong>Conexão</strong>
                  <span>Interface demonstrativa</span>
                </div>
                <div>
                  <ShieldCheck size={23} />
                  <strong>Autenticação RFID</strong>
                  <span>Aguardando integração</span>
                </div>
                <div>
                  <PackageOpen size={23} />
                  <strong>Sensor óptico</strong>
                  <span>Aguardando integração</span>
                </div>
                <div>
                  <Bell size={23} />
                  <strong>Alarme sonoro e LED</strong>
                  <span>Aguardando integração</span>
                </div>
              </div>
            </div>

            <div className="alert-box sun-alert">
              <Sun size={25} />
              <div>
                <strong>Orientação de instalação</strong>
                <p>
                  Instale o dispensador em um ambiente seco, protegido
                  da luz solar direta e conforme as condições de
                  armazenamento indicadas para os medicamentos.
                </p>
              </div>
            </div>

            <div className="late-notice">
              <WifiOff size={21} />
              <div>
                <strong>Integração pendente</strong>
                <p>
                  A conexão real com o ESP32, os sensores e o Firebase
                  será implementada na próxima etapa do projeto.
                </p>
              </div>
            </div>
          </section>
        )}

        <footer>
          MedCare © 2026 • Sistema de Gestão de Controle de Medicação
        </footer>

      </main>
    </div>
  );
}

export default App;
