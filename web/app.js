// Tela "Bolsa" (03-FLUXO §2.1, §4; 04-DESIGN). Só exibe e repassa escolhas; o servidor decide tudo.
'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'street_uniformbag';
const $ = (id) => document.getElementById(id);

let state = null;     // { data, playerModel, t }
let pendingSlot = null;

function post(name, body) {
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body || {}),
    }).catch(() => null);
}

function text(id, value) { $(id).textContent = value ?? ''; }

function formatDate(value) {
    if (value === null || value === undefined) return '';
    const date = typeof value === 'number' ? new Date(value) : new Date(String(value).replace(' ', 'T'));
    return isNaN(date) ? String(value) : date.toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
}

function applyColor(color) {
    if (typeof color === 'string' && /^#[0-9a-fA-F]{6}$/.test(color)) {
        document.documentElement.style.setProperty('--color-primary', color);
    }
}

function render() {
    const { data, playerModel, t } = state;
    const slotsByNo = new Map(data.slots.map((s) => [s.slot, s]));
    const used = data.slots.length;
    const full = used >= data.slotCount;
    const hasVariant = data.uniform.models.includes(playerModel);

    text('t-title', t.title);
    text('uniform-name', data.uniform.name);
    text('org-label', data.uniform.orgLabel);
    text('bag-id', data.bagId);
    text('t-official', t.official);
    text('official-name', data.uniform.name);
    text('t-slots', t.slots);
    text('t-working', t.working);
    text('slot-counter', `${used} de ${data.slotCount} ${t.occupied}`);

    const btnUniform = $('btn-uniform');
    btnUniform.textContent = t.wearUniform;
    btnUniform.disabled = !hasVariant || full;
    text('official-hint', !hasVariant ? t.noVariant : (full ? t.fullHint : ''));

    const list = $('slot-list');
    list.replaceChildren();

    for (let n = 1; n <= data.slotCount; n++) {
        const slot = slotsByNo.get(n);
        const row = document.createElement('div');
        row.className = 'slot';

        const info = document.createElement('div');
        const title = document.createElement('div');
        title.className = 'slot-title';
        title.textContent = `${n}. ${slot ? (slot.storedBy || '?') : t.free}`;

        if (slot && slot.isUniform) {
            const b = document.createElement('span');
            b.className = 'badge';
            b.textContent = t.uniformBadge;
            title.appendChild(b);
        }

        const compatible = slot && slot.model === playerModel;
        if (slot && !compatible) {
            const b = document.createElement('span');
            b.className = 'badge badge-warn';
            b.textContent = t.incompatible;
            title.appendChild(b);
        }

        info.appendChild(title);
        if (slot) {
            const sub = document.createElement('div');
            sub.className = 'slot-sub';
            sub.textContent = `${t.storedBy} ${formatDate(slot.storedAt)}`;
            info.appendChild(sub);
        }
        row.appendChild(info);

        if (slot) {
            const btn = document.createElement('button');
            btn.className = 'btn btn-secondary';
            btn.textContent = t.wearThis;
            btn.disabled = !compatible;
            btn.addEventListener('click', () => openConfirm(n, slot));
            row.appendChild(btn);
        }
        list.appendChild(row);
    }

    text('btn-collect', t.collect);
    text('btn-close', t.close);
    text('preview-hint', t.previewHint);
    list.querySelectorAll('.slot').forEach((row, i) => {
        const slot = slotsByNo.get(i + 1);
        bindPreview(row, 'compartimento', i + 1, !!slot && slot.model === playerModel);
    });
}

// Prévia ao passar o mouse (D204): o cliente mostra uma cópia do personagem com a roupa.
let previewTimer = null;
function bindPreview(el, kind, slot, enabled) {
    if (!el || !enabled) return;
    el.addEventListener('mouseenter', () => {
        clearTimeout(previewTimer);
        previewTimer = setTimeout(() => post('preview', { kind, slot }), 150);
    });
    el.addEventListener('mouseleave', () => {
        clearTimeout(previewTimer);
        post('previewEnd');
    });
}

function openConfirm(n, slot) {
    const { t } = state;
    pendingSlot = n;
    text('t-confirm-title', t.confirmTitle);
    text('t-will-wear', t.willWear);
    text('t-will-store', `${t.willStore} ${n}`);
    $('confirm-wear').textContent = `${n}. ${slot.storedBy || '?'} — ${formatDate(slot.storedAt)}${slot.isUniform ? ` (${t.uniformBadge})` : ''}`;
    $('confirm-store').textContent = t.currentOutfit;
    text('btn-back', t.back);
    text('btn-confirm', t.confirm);
    $('confirm').classList.remove('hidden');
}

function closeConfirm() {
    pendingSlot = null;
    $('confirm').classList.add('hidden');
}

function setBusy(value) {
    $('busy').classList.toggle('hidden', !value);
    document.querySelectorAll('.panel button, .modal button').forEach((b) => {
        if (value) { b.dataset.wasDisabled = b.disabled ? '1' : ''; b.disabled = true; }
        else { b.disabled = b.dataset.wasDisabled === '1'; }
    });
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') {
        state = { data: msg.data, playerModel: msg.playerModel, t: msg.locale };
        applyColor(msg.data.color);
        closeConfirm();
        render();
        setBusy(false);
        $('app').classList.remove('hidden');
    } else if (msg.action === 'close') {
        closeConfirm();
        $('app').classList.add('hidden');
        state = null;
    } else if (msg.action === 'hide') {
        closeConfirm();
        $('app').classList.add('hidden');
    } else if (msg.action === 'update' && state) {
        state.data.slots = Array.isArray(msg.slots) ? msg.slots : state.data.slots;
        render();
    } else if (msg.action === 'busy') {
        if (msg.value) closeConfirm();
        setBusy(!!msg.value);
    }
});

$('btn-uniform').addEventListener('click', () => post('wearUniform'));

// Prévia do uniforme oficial: ligada uma vez; só dispara se houver versão para o personagem.
const officialCard = document.querySelector('.card-official');
officialCard.addEventListener('mouseenter', () => {
    if (!state || !state.data.uniform.models.includes(state.playerModel)) return;
    clearTimeout(previewTimer);
    previewTimer = setTimeout(() => post('preview', { kind: 'uniforme' }), 150);
});
officialCard.addEventListener('mouseleave', () => {
    clearTimeout(previewTimer);
    post('previewEnd');
});
$('btn-collect').addEventListener('click', () => { post('previewEnd'); post('collect'); });
$('btn-close').addEventListener('click', () => { post('previewEnd'); post('close'); });
$('btn-back').addEventListener('click', closeConfirm);
$('btn-confirm').addEventListener('click', () => {
    const n = pendingSlot;
    closeConfirm();
    if (n) post('wearSlot', { slot: n });
});

document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape' || !state) return;
    if (!$('confirm').classList.contains('hidden')) closeConfirm();
    else { post('previewEnd'); post('close'); }
});
