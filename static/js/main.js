/* ================================================================
   ANNUAIRE STATISTIQUE — main.js  (refactorisé v2)
   ================================================================ */

// Enregistrement global du plugin datalabels pour Chart.js 4
if (typeof ChartDataLabels !== 'undefined') {
  Chart.register(ChartDataLabels);
}

// ── Sidebar mobile toggle ────────────────────────────────────────
function toggleSidebar() {
  document.querySelector('.sidebar').classList.toggle('open');
}
document.addEventListener('click', (e) => {
  const sidebar = document.querySelector('.sidebar');
  const toggle  = document.querySelector('.menu-toggle');
  if (sidebar && toggle && !sidebar.contains(e.target) && !toggle.contains(e.target)) {
    sidebar.classList.remove('open');
  }
});

// Theme premium clair/sombre
function applyTheme(theme) {
  document.body.classList.toggle('theme-dark', theme === 'dark');
}

function toggleTheme() {
  const next = document.body.classList.contains('theme-dark') ? 'light' : 'dark';
  localStorage.setItem('annuaire-theme', next);
  applyTheme(next);
}

document.addEventListener('DOMContentLoaded', () => {
  applyTheme(localStorage.getItem('annuaire-theme') || 'light');
});

// ── Auto-dismiss flash messages (5 secondes) ─────────────────────
setTimeout(() => {
  document.querySelectorAll('.flash').forEach(el => {
    el.style.transition = 'opacity .5s, transform .5s';
    el.style.opacity = '0';
    el.style.transform = 'translateY(-8px)';
    setTimeout(() => el.remove(), 500);
  });
}, 5000);

// ── Confirm delete dialogs ───────────────────────────────────────
document.addEventListener('submit', (e) => {
  const form = e.target;
  if (form.classList.contains('confirm-delete')) {
    const name = form.dataset.name || 'cet élément';
    if (!confirm(`Confirmer la suppression de ${name} ?\nCette action est irréversible.`)) {
      e.preventDefault();
    }
  }
});

// ── Progress bar animation ───────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.progress-fill[data-width]').forEach(bar => {
    setTimeout(() => { bar.style.width = bar.dataset.width; }, 200);
  });
});

// ── Toggle password visibility ───────────────────────────────────
function togglePassword(inputId) {
  const input = document.getElementById(inputId);
  if (!input) return;
  input.type = input.type === 'password' ? 'text' : 'password';
}

/* ================================================================
   PALETTE COULEURS PARTAGÉE
   ================================================================ */
const PALETTE = {
  orange:      '#F47B20',
  orangeDark:  '#C85F13',
  orangeLight: '#FFF4EA',
  green:       '#149447',
  greenDark:   '#0B6F35',
  blue:        '#2563A6',
  red:         '#C2412D',
  gray:        '#8A94A6',
  purple:      '#6F7A8A',
  yellow:      '#D6A23D',
  teal:        '#1D8F78',
};
const SERIES_COLORS = [
  PALETTE.orange, PALETTE.green, PALETTE.yellow, PALETTE.blue,
  PALETTE.teal, PALETTE.red, PALETTE.gray, PALETTE.orangeDark,
];

/* Options communes pour tooltips */
const sharedTooltip = {
  backgroundColor: 'rgba(15,23,42,.88)',
  titleColor: '#fff',
  bodyColor:  'rgba(255,255,255,.85)',
  padding: 10,
  cornerRadius: 8,
  titleFont: { size: 12, weight: '600' },
  bodyFont:  { size: 12 },
};

/* ================================================================
   DASHBOARD CHARTS
   ================================================================ */
/* ================================================================
   DASHBOARD CHARTS
   ================================================================ */
function initDashboardCharts(sexeData, ageData, evolution_data) {

  /* ── Chart 1 : Répartition par sexe ───────────────────────── */
  const ctxSexe = document.getElementById('chartSexe');

  if (ctxSexe && sexeData.length) {
    const labels = sexeData.map(d => d.sexe);
    const values = sexeData.map(d => d.count);
    const total = values.reduce((a, b) => a + b, 0);

   new Chart(ctxSexe, {
  type: 'doughnut',
  plugins: [ChartDataLabels],

  data: {
    labels: labels,
    datasets: [{
      data: values,
      backgroundColor: [
        PALETTE.blue,
        PALETTE.orange,
        PALETTE.green,
        PALETTE.gray
      ],
      borderWidth: 3,
      borderColor: '#fff',
      hoverOffset: 10
    }]
  },

  options: {
    plugins: {

      datalabels: {
        color: '#fff', // couleur blanche

        font: {
          size: 13,
          weight: 'bold'
        },

        formatter: (v) => total > 0 && v / total > 0.05 ? Math.round(v / total * 100) + '%' : '',
      }

    }
  }
});
  }

    /* ── Chart 2 : Pyramide des âges (Barres horizontales) ─────── */
  const ctxAge = document.getElementById('chartAge');
  if (ctxAge && ageData.length) {
    const maxVal = Math.max(...ageData.map(d => d.count));

    new Chart(ctxAge, {
      type: 'bar',
      plugins: [ChartDataLabels],
      data: {
        labels: ageData.map(d => d.tranche),
        datasets: [{
          label: 'Habitants',
          data: ageData.map(d => d.count),
          backgroundColor: ageData.map((_, i) => SERIES_COLORS[i % SERIES_COLORS.length] + 'CC'),
          borderRadius: 6,
          borderSkipped: false,
        }]
      },
      options: {
        indexAxis: 'y',
        plugins: {
          legend: { display: false },
          tooltip: {
            ...sharedTooltip,
            callbacks: {
              label: ctx => ` ${ctx.raw} habitant(s)`
            }
          },
          datalabels: {
            anchor: 'end', align: 'end',
            color: '#475569',
            font: { size: 10, weight: '600' },
            formatter: (v) => v > 0 ? v : '',
          }
        },
        scales: {
          x: {
            grid: { color: 'rgba(0,0,0,.06)' },
            ticks: { font: { size: 10 }, stepSize: 1 },
            title: { display: true, text: 'Nombre d\'habitants', font: { size: 11 }, color: '#64748b' },
            suggestedMax: maxVal + Math.ceil(maxVal * 0.15),
          },
          y: {
            grid: { display: false },
            ticks: { font: { size: 10 }, 
            
          }
          }
        }
      }
    });
  }

  /* ── Chart 3 : Évolution journalière sur toute la période ─── */
  const ctxEvo = document.getElementById('chartEvolution');

  if (ctxEvo && evolution_data.length) {
    new Chart(ctxEvo, {
      type: 'line',
      plugins: [ChartDataLabels],
      data: {
        labels: evolution_data.map(d => d.jour),
        datasets: [
          {
            label: 'Naissances',
            data: evolution_data.map(d => d.naissances),
            borderColor: PALETTE.green,
            backgroundColor: PALETTE.green + '20',
            fill: true,
            tension: 0.4,
            pointBackgroundColor: PALETTE.green,
            pointRadius: 5,
            pointHoverRadius: 7
          },
          {
            label: 'Décès',
            data: evolution_data.map(d => d.deces),
            borderColor: PALETTE.red,
            backgroundColor: PALETTE.red + '15',
            fill: true,
            tension: 0.4,
            pointBackgroundColor: PALETTE.red,
            pointRadius: 5,
            pointHoverRadius: 7
          }
        ]
      },
      options: {
        plugins: {
          legend: {
            position: 'top',
            labels: {
              padding: 16,
              font: { size: 12 },
              usePointStyle: true
            }
          },
          tooltip: {
            ...sharedTooltip,
            mode: 'index',
            intersect: false
          },
          datalabels: {
            display: ctx => ctx.dataset.data[ctx.dataIndex] > 0,
            anchor: 'end',
            align: 'top',
            color: ctx => ctx.datasetIndex === 0 ? PALETTE.greenDark : '#991b1b',
            font: { size: 10, weight: '600' },
            formatter: v => v
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              maxTicksLimit: 15
            }
          },
          y: {
            grid: { color: 'rgba(0,0,0,.06)' },
            beginAtZero: true,
            ticks: { stepSize: 1 },
            title: {
              display: true,
              text: "Nombre d'événements",
              font: { size: 11 },
              color: '#64748b'
            }
          }
        },
        interaction: {
          mode: 'index',
          intersect: false
        }
      }
    });
  }

} // Fin de initDashboardCharts
/* ================================================================
   RAPPORT CHARTS (Dashboard — section analyse socio-pro)
   ================================================================ */
function initRapportCharts(professions, niveaux, evolution) {

  /* ── Top professions (Bar verticale) ──────────────────────────── */
  const ctxProf = document.getElementById('chartProfessions');
  if (ctxProf && professions.length) {
    new Chart(ctxProf, {
      type: 'bar',
      plugins: [ChartDataLabels],
      data: {
        labels: professions.map(p => p.profession),
        datasets: [{
          data: professions.map(p => p.cnt),
          backgroundColor: SERIES_COLORS,
          borderRadius: 6,
          borderSkipped: false,
        }]
      },
      options: {
        plugins: {
          legend: { display: false },
          tooltip: {
            ...sharedTooltip,
            callbacks: { label: ctx => ` ${ctx.raw} personne(s)` }
          },
          datalabels: {
            anchor: 'end', align: 'end',
            color: '#475569',
            font: { size: 11, weight: '600' },
            formatter: (v) => v > 0 ? v : '',
          }
        },
        scales: {
          x: { grid: { display: false }, ticks: { font: { size: 11 }, maxRotation: 30 } },
          y: {
            grid: { color: 'rgba(0,0,0,.06)' },
            beginAtZero: true,
            ticks: { stepSize: 1 },
            title: { display: true, text: 'Effectif', font: { size: 11 }, color: '#64748b' }
          }
        }
      }
    });
  }

  /* ── Niveaux d'étude (donut) ─────────────────────────────────── */
  const ctxNiv = document.getElementById('chartNiveaux');
  if (ctxNiv && niveaux.length) {
    const total = niveaux.reduce((a, n) => a + n.cnt, 0);

    new Chart(ctxNiv, {
      type: 'doughnut',
      plugins: [ChartDataLabels],
      data: {
        labels: niveaux.map(n => n.niveau_etude),
        datasets: [{
          data: niveaux.map(n => n.cnt),
          backgroundColor: SERIES_COLORS,
          borderWidth: 3,
          borderColor: '#fff',
        }]
      },
      options: {
        plugins: {
          legend: { position: 'right', labels: { padding: 14, font: { size: 11 }, usePointStyle: true } },
          tooltip: {
            ...sharedTooltip,
            callbacks: {
              label: ctx => ` ${ctx.label} : ${ctx.raw} (${Math.round(ctx.raw / total * 100)}%)`
            }
          },
          datalabels: {
            color: '#fff',
            font: { size: 11, weight: '700' },
            formatter: (v) => total > 0 && v / total > 0.05 ? Math.round(v / total * 100) + '%' : '',
          }
        }
      }
    });
  }

  /* ── Évolution naissances / décès 12 mois (Bar groupée) ──────── */
  const ctxEvo = document.getElementById('chartEvoRap');
  if (ctxEvo && evolution.length) {
    new Chart(ctxEvo, {
      type: 'bar',
      plugins: [ChartDataLabels],
      data: {
        labels: evolution.map(d => d.mois),
        datasets: [
          {
            label: 'Naissances',
            data: evolution.map(d => d.naissances),
            backgroundColor: PALETTE.green + 'CC',
            borderRadius: 4,
          },
          {
            label: 'Décès',
            data: evolution.map(d => d.deces),
            backgroundColor: PALETTE.red + 'CC',
            borderRadius: 4,
          }
        ]
      },
      options: {
        plugins: {
          legend: { position: 'top', labels: { usePointStyle: true } },
          tooltip: { ...sharedTooltip, mode: 'index', intersect: false },
          datalabels: {
            anchor: 'end', align: 'end',
            color: (ctx) => ctx.datasetIndex === 0 ? PALETTE.greenDark : '#991b1b',
            font: { size: 10, weight: '600' },
            formatter: (v) => v > 0 ? v : '',
          }
        },
        scales: {
          x: { grid: { display: false } },
          y: {
            grid: { color: 'rgba(0,0,0,.06)' },
            beginAtZero: true,
            ticks: { stepSize: 1 },
            title: { display: true, text: 'Nombre d\'événements', font: { size: 11 }, color: '#64748b' }
          }
        },
        interaction: { mode: 'index', intersect: false },
      }
    });
  }
}
