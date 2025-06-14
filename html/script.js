/* ----------   HUD & pusula güncellemeleri   ---------- */
window.addEventListener('message', (event) => {
  const d = event.data;

  /* pusula */
  if (d.show !== undefined) {
    document.getElementById('compass').style.display = d.show ? 'flex' : 'none';
  }
  if (d.direction) document.getElementById('direction').textContent = d.direction;
  if (d.street)    document.getElementById('street').textContent   = d.street;
  if (d.zone)      document.getElementById('zone').textContent     = d.zone;

  /* oyuncu info */
  const playerInfoContainer = document.getElementById('player-info');

  if (d.showPlayerInfo === false) {
    playerInfoContainer.style.display = 'none';
    return;
  }

  if (d.showPlayerInfo === true) {
    playerInfoContainer.style.display = 'block';
  }

  if (d.playerName && d.playerId !== undefined) {
    document.getElementById('player-name-id').innerHTML =
      `<i class="fa-solid fa-user"></i>${d.playerId} - ${d.playerName} `;
  }

  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');

  document.getElementById('date').innerHTML =
    `<i class="fa-solid fa-calendar"></i>${pad(now.getDate())}.${pad(now.getMonth() + 1)}.${now.getFullYear()}`;
  document.getElementById('system-time').innerHTML =
    `<i class="fa-solid fa-clock"></i>${pad(now.getHours())}:${pad(now.getMinutes())} `;

  if (d.gameTime) {
    document.getElementById('game-time').innerHTML =
      `<i class="fa-regular fa-clock"></i>${d.gameTime} `;
  }

  /* hız‑vites‑kemer */
  if (d.showHud !== undefined)
    document.getElementById('hud').style.display = d.showHud ? 'flex' : 'none';

  if (d.speed !== undefined)
    document.getElementById('speed').textContent = d.speed.toString().padStart(3,'0');

  if (d.gear !== undefined && d.gear !== null)
    document.getElementById('gear').textContent = d.gear;

  if (d.seatbeltOn !== undefined) {
    document.getElementById('belt').className = d.seatbeltOn ? 'belt-on' : 'belt-off';
  }

  /* Tüm HUD’u tek seferde gizle/göster (hudSwitch) */
  if (d.showAll !== undefined) {
    ['compass','player-info','hud'].forEach(id =>
      document.getElementById(id).style.display = d.showAll ? '' : 'none');
  }

  /* Switch kutusunu aç / kapa */
  if (d.type === 'toggleUi') {
    document.querySelector('.switch-box').style.display = d.state ? 'flex' : 'none';
  }
});

/* ----------   MENÜ (switch‑box) işlemleri   ---------- */
document.querySelector('.switch-box').style.display = 'none';

document.addEventListener('keydown', (e) => {
  if (e.key === 'Backspace') {
    fetch(`https://${GetParentResourceName()}/closeUi`,{method:'POST'});
    document.querySelector('.switch-box').style.display = 'none';
  }
});

const send = (url,obj)=>
  fetch(`https://${GetParentResourceName()}/${url}`,{
    method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify(obj)
  });

document.getElementById('compassSwitch').onchange = e =>
  send('togglePusula',{enabled:e.target.checked});

document.getElementById('hudSwitch').onchange = e => {
  const enabled = e.target.checked;
  send('toggleHud', { enabled });

  document.getElementById('player-info').style.display = enabled ? 'block' : 'none';
};

const topBar  = document.querySelector('.black-bars.top');
const botBar  = document.querySelector('.black-bars.bottom');
document.getElementById('cinematicSwitch').onchange = e =>{
  const on=e.target.checked;
  topBar.style.display=botBar.style.display=on?'block':'none';
};
