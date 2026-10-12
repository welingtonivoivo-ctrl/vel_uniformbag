// Painel de gestão — parte 1: Uniformes, Emissão, Bolsas (03-FLUXO §2.2, D205, D206).
// Só monta a tela e repassa pedidos; o servidor valida perfil e dados em toda chamada.
'use strict';

(() => {
    const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'vel_uniformbag';
    const MODELS = [['mp_m_freemode_01', 'male'], ['mp_f_freemode_01', 'female']];

    let P = null; // { data, t, org, tab, uniforms, edit, stashes }

    const nui = (name, body) => fetch(`https://${RES}/${name}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(body || {}),
    }).then((r) => r.json()).catch(() => ({ error: 'nui', message: 'Sem resposta do servidor. Tente novamente.' }));

    const call = (fn, ...args) => nui('panel', { fn, args });

    function el(tag, attrs, ...children) {
        const node = document.createElement(tag);
        for (const [k, v] of Object.entries(attrs || {})) {
            if (v === undefined || v === null || v === false) continue;
            if (k === 'class') node.className = v;
            else if (k === 'text') node.textContent = v;
            else if (k.startsWith('on')) node.addEventListener(k.slice(2), v);
            else if (k === 'value') node.value = v;
            else if (k === 'checked') node.checked = !!v;
            else node.setAttribute(k, v === true ? '' : v);
        }
        for (const c of children.flat()) if (c !== null && c !== undefined && c !== false) node.append(c);
        return node;
    }

    const fmtDate = (v) => {
        if (v === null || v === undefined) return '—';
        const d = typeof v === 'number' ? new Date(v) : new Date(String(v).replace(' ', 'T'));
        return isNaN(d) ? String(v) : d.toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
    };

    const org = () => P.data.orgs.find((o) => o.name === P.org);
    const gradeName = (lvl) => (org()?.grades.find((g) => g.level === Number(lvl))?.name) || String(lvl);

    function summary(u) {
        if (u.auth_mode === 'faixa') {
            const max = u.grade_max === null || u.grade_max === undefined ? P.t.no_max : gradeName(u.grade_max);
            return `${gradeName(u.grade_min)} → ${max}`;
        }
        return (u.grades || []).map(gradeName).join(', ');
    }

    function setMsg(id, text, ok) {
        const m = document.getElementById(id);
        if (!m) return;
        m.textContent = text || '';
        m.className = `pn-msg ${ok ? 'ok' : 'err'}`;
    }

    // ------------------------------------------------------------------ Estrutura

    function shell() {
        const t = P.t;
        const root = document.getElementById('panel-root');
        root.replaceChildren(
            el('div', { class: 'pn-backdrop', id: 'pn-backdrop' },
                el('div', { class: 'pn' },
                    el('div', { class: 'pn-header' },
                        el('h1', { text: t.title }),
                        el('label', { class: 'field' }, t.org,
                            el('select', { id: 'pn-org', onchange: (e) => { P.org = e.target.value; P.edit = null; load(); } },
                                P.data.orgs.map((o) => el('option', { value: o.name, text: `${o.label} (${o.name})` })))),
                        el('button', { class: 'btn btn-secondary', text: t.open_store, title: t.store_hint, onclick: () => nui('openStore') }),
                        el('button', { class: 'btn btn-secondary', text: t.close, onclick: close })),
                    el('div', { class: 'pn-tabs' },
                        [['uniforms', t.tab_uniforms], ['issue', t.tab_issue], ['bags', t.tab_bags], ['alerts', t.tab_alerts], ['points', t.tab_points], ['audit', t.tab_audit],
                            P.data.admin ? ['recovery', t.tab_recovery] : null].filter(Boolean).map(([id, label]) =>
                            el('button', { class: `pn-tab ${P.tab === id ? 'active' : ''}`, text: label, onclick: () => { P.tab = id; shell(); load(); } }))),
                    el('div', { class: 'pn-body', id: 'pn-body' }))));
        document.getElementById('pn-org').value = P.org;
    }

    function close() {
        if (EMBED) {
            // Dentro do mri_Qadmin: pede para ele fechar o painel (protocolo de plugin).
            window.parent.postMessage({ type: 'mri-plugin/request-close' }, '*');
            nui('panelClose');
            return;
        }
        document.getElementById('panel-root').replaceChildren();
        P = null;
        nui('panelClose');
    }

    async function load() {
        const body = document.getElementById('pn-body');
        body.replaceChildren(el('div', { class: 'pn-col pn-empty', text: P.t.loading }));
        if (P.tab === 'uniforms') return loadUniforms();
        if (P.tab === 'issue') return loadIssue();
        if (P.tab === 'alerts') return loadAlerts();
        if (P.tab === 'audit') return loadAudit();
        if (P.tab === 'recovery') return loadRecovery();
        if (P.tab === 'points') return loadPoints();
        return loadBags();
    }

    // ------------------------------------------------------------------ Pontos nas sedes (D89–D93)

    async function loadPoints() {
        const t = P.t;
        const res = await call('points', P.org);
        if (!P) return;
        if (res.error) return document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-msg err', text: res.message }));
        const form = { label: '' };

        document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-main' },
            el('div', { class: 'pn-item-sub', text: t.points_hint }),
            res.canEdit ? el('div', { class: 'pn-row' },
                el('label', { class: 'field' }, t.point_label, el('input', { type: 'text', maxlength: 80, placeholder: t.point_placeholder, oninput: (e) => { form.label = e.target.value; } })),
                el('button', { class: 'btn btn-primary', text: t.point_add, onclick: async () => {
                    const r = await call('addPoint', P.org, form.label);
                    if (r.error) return setMsg('pn-point-msg', r.message, false);
                    setMsg('pn-point-msg', t.saved, true);
                    loadPoints();
                } })) : el('div', { class: 'pn-item-sub', text: t.points_staff_only }),
            el('div', { class: 'pn-msg', id: 'pn-point-msg' }),
            (res.points || []).length === 0 ? el('div', { class: 'pn-empty', text: t.no_results }) :
                el('table', { class: 'pn-table' },
                    el('thead', {}, el('tr', {}, [t.point_label, t.location, t.status, ''].map((h) => el('th', { text: h })))),
                    el('tbody', {}, res.points.map((p) => el('tr', {},
                        el('td', { text: p.label }),
                        el('td', { class: 'mono', text: `${Number(p.x).toFixed(1)}, ${Number(p.y).toFixed(1)}, ${Number(p.z).toFixed(1)}` }),
                        el('td', { text: p.active ? t.active : t.inactive }),
                        el('td', {}, res.canEdit ? el('button', { class: `btn btn-sm ${p.active ? 'btn-danger' : 'btn-secondary'}`, text: p.active ? t.deactivate : t.activate, onclick: async () => {
                            const r = await call('togglePoint', p.id, !p.active);
                            if (r.error) return setMsg('pn-point-msg', r.message, false);
                            loadPoints();
                        } }) : null)))))));
    }

    // ------------------------------------------------------------------ Alertas e logs

    function checkList(options, selected, onChange) {
        return el('div', { class: 'pn-checks' }, options.map(([value, label]) =>
            el('label', { class: 'pn-check' },
                el('input', { type: 'checkbox', checked: selected.includes(value), onchange: (e) => {
                    onChange(e.target.checked ? [...selected.filter((x) => x !== value), value] : selected.filter((x) => x !== value));
                } }), label)));
    }

    async function loadAlerts() {
        const t = P.t;
        const res = await call('alertSettings', P.org);
        if (!P) return;
        if (res.error) return document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-msg err', text: res.message }));
        const s = res.settings;

        const typesBox = el('div');
        const namesBox = el('div');
        const logsBox = el('div');
        const drawLists = () => {
            typesBox.replaceChildren(checkList(res.jobTypes.map((x) => [x, x]), s.jobTypes, (v) => { s.jobTypes = v; drawLists(); }));
            namesBox.replaceChildren(checkList(res.jobNames.map((j) => [j.name, `${j.label} (${j.name})`]), s.jobNames, (v) => { s.jobNames = v; drawLists(); }));
            logsBox.replaceChildren(checkList(CATEGORIES.map((c) => [c, c]), s.logCategories || [], (v) => { s.logCategories = v; drawLists(); }));
        };
        const hook = (on) => el('span', { class: `badge ${on ? '' : 'badge-warn'}`, text: on ? t.webhook_on : t.webhook_off });
        drawLists();

        document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-main' },
            res.psdispatch ? null : el('div', { class: 'pn-msg err', text: t.psdispatch_off }),
            el('label', { class: 'pn-switch' }, el('input', { type: 'checkbox', checked: s.enabled, onchange: (e) => { s.enabled = e.target.checked; } }), t.alert_enabled),
            el('label', { class: 'field' }, t.alert_mode,
                el('select', { onchange: (e) => { s.mode = e.target.value; } },
                    [['psdispatch', t.mode_psdispatch], ['jobnotify', t.mode_jobnotify], ['ambos', t.mode_both]]
                        .map(([v, l]) => el('option', { value: v, text: l, selected: s.mode === v || undefined })))),
            el('div', { class: 'pn-section' }, el('h3', { text: t.job_types }), el('div', { class: 'pn-item-sub', text: t.job_types_hint }), typesBox),
            el('div', { class: 'pn-section' }, el('h3', { text: t.job_names }), el('div', { class: 'pn-item-sub', text: t.job_names_hint }), namesBox,
                el('label', { class: 'pn-switch' }, el('input', { type: 'checkbox', checked: s.onDutyOnly, onchange: (e) => { s.onDutyOnly = e.target.checked; } }), t.onduty_only)),
            el('div', { class: 'pn-row' },
                el('label', { class: 'field' }, t.blip_seconds, el('input', { type: 'number', min: 30, max: 900, value: s.blipSeconds, onchange: (e) => { s.blipSeconds = Number(e.target.value); } })),
                el('label', { class: 'field' }, t.alert_code, el('input', { type: 'text', maxlength: 10, value: s.code, oninput: (e) => { s.code = e.target.value; } })),
                el('label', { class: 'field' }, t.item_image, el('input', { type: 'text', maxlength: 60, value: s.itemImage, placeholder: 'uniform_bag', title: t.item_image_hint, oninput: (e) => { s.itemImage = e.target.value.trim(); } })),
                el('label', { class: 'field' }, t.default_stash, el('input', { type: 'text', maxlength: 80, value: s.defaultStash, oninput: (e) => { s.defaultStash = e.target.value.trim(); } }))),
            el('div', { class: 'pn-item-sub', text: t.item_image_hint }),
            el('div', { class: 'pn-section' }, el('h3', { text: t.discord }),
                el('div', { class: 'pn-item-sub' }, `${t.webhook_org}: `, hook(res.webhookOrg), ' · ', `${t.webhook_admin}: `, hook(res.webhookAdmin)),
                el('div', { class: 'pn-item-sub', text: t.discord_hint.replace('%s', P.org) }),
                logsBox),
            el('div', { class: 'pn-row' }, el('button', { class: 'btn btn-primary', text: t.save, onclick: async () => {
                const r = await call('saveAlertSettings', P.org, s);
                setMsg('pn-alert-msg', r.error ? r.message : t.saved, !r.error);
            } })),
            el('div', { class: 'pn-msg', id: 'pn-alert-msg' })));
    }

    // ------------------------------------------------------------------ Auditoria

    const CATEGORIES = ['emissao', 'retirada', 'transferencia', 'devolucao', 'troca', 'uso_indevido', 'mudanca_cargo',
        'pendente_verificacao', 'admin', 'recuperacao', 'duplicacao', 'sistema'];

    async function loadAudit() {
        const t = P.t;
        P.auditFilter = P.auditFilter || { category: '', bagId: '', actor: '', page: 0 };
        const f = P.auditFilter;
        const res = await call('audit', P.org, f);
        if (!P) return;
        if (res.error) return document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-msg err', text: res.message }));

        const reload = () => { f.page = 0; loadAudit(); };
        document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-main' },
            el('div', { class: 'pn-row' },
                el('label', { class: 'field' }, t.category,
                    el('select', { onchange: (e) => { f.category = e.target.value; reload(); } },
                        el('option', { value: '', text: t.all }),
                        CATEGORIES.map((c) => el('option', { value: c, text: c, selected: f.category === c || undefined })))),
                el('label', { class: 'field' }, t.bag_id, el('input', { type: 'text', value: f.bagId, placeholder: 'UB-', onchange: (e) => { f.bagId = e.target.value; reload(); } })),
                el('label', { class: 'field' }, t.actor, el('input', { type: 'text', value: f.actor, onchange: (e) => { f.actor = e.target.value; reload(); } }))),
            res.rows.length === 0 ? el('div', { class: 'pn-empty', text: t.no_results }) :
                el('table', { class: 'pn-table' },
                    el('thead', {}, el('tr', {}, [t.when, t.category, t.action, t.bag_id, t.actor, t.details].map((h) => el('th', { text: h })))),
                    el('tbody', {}, res.rows.map((r) => el('tr', {},
                        el('td', { text: fmtDate(r.created_at) }),
                        el('td', { text: r.category }),
                        el('td', { text: r.action }),
                        el('td', { class: 'mono', text: r.bag_id || '—' }),
                        el('td', { text: r.actor_name || r.actor_citizenid || '—' }),
                        el('td', { class: 'pn-item-sub', text: r.data || '' }))))),
            el('div', { class: 'pn-row' },
                el('button', { class: 'btn btn-secondary btn-sm', text: t.previous, disabled: f.page === 0 || undefined, onclick: () => { f.page -= 1; loadAudit(); } }),
                el('span', { class: 'pn-item-sub', text: String(f.page + 1) }),
                el('button', { class: 'btn btn-secondary btn-sm', text: t.next, disabled: !res.hasMore || undefined, onclick: () => { f.page += 1; loadAudit(); } }))));
    }

    // ------------------------------------------------------------------ Recuperação (só staff)

    function loadRecovery() {
        const t = P.t;
        const results = el('div', { class: 'pn-list', style: 'width:auto;border:none;padding:0' });
        const detail = el('div', { class: 'pn-main' }, el('div', { class: 'pn-empty', text: t.recovery_note }));

        const search = async (q) => {
            const r = await call('findCharacter', q);
            if (!P) return;
            results.replaceChildren(...((r.results || []).length === 0 ? [el('div', { class: 'pn-empty', text: t.no_results })] :
                r.results.map((c) => el('div', { class: 'pn-item', onclick: () => openChar(c) },
                    el('div', { class: 'pn-item-title', text: `${c.firstname || ''} ${c.lastname || ''}` }),
                    el('div', { class: 'pn-item-sub mono', text: c.citizenid })))));
        };

        const openChar = async (c) => {
            const r = await call('recoverySources', c.citizenid);
            if (!P) return;
            if (r.error) return detail.replaceChildren(el('div', { class: 'pn-msg err', text: r.message }));
            const form = { source: null, reason: '' };
            detail.replaceChildren(
                el('h2', { text: `${c.firstname || ''} ${c.lastname || ''} (${c.citizenid})` }),
                el('div', { class: 'pn-item-sub', text: t.recovery_note }),
                el('div', { class: 'pn-section' }, el('h3', { text: t.choose_source }),
                    (r.sources || []).length === 0 ? el('div', { class: 'pn-empty', text: t.no_results }) :
                        r.sources.map((s) => el('label', { class: 'pn-check', style: 'margin-bottom:6px' },
                            el('input', { type: 'radio', name: 'rec-src', onchange: () => { form.source = s; } }),
                            `${fmtDate(s.at)} · ${s.label}`))),
                el('label', { class: 'field' }, `${t.reason} — ${t.reason_hint}`,
                    el('input', { type: 'text', maxlength: 500, oninput: (e) => { form.reason = e.target.value; } })),
                el('div', { class: 'pn-row' }, el('button', { class: 'btn btn-primary', text: t.register, onclick: async () => {
                    if (!form.source) return setMsg('pn-rec-msg', t.choose_source, false);
                    const res = await call('createRecovery', c.citizenid, form.source.type, form.source.id, form.reason);
                    if (res.error) return setMsg('pn-rec-msg', res.message, false);
                    setMsg('pn-rec-msg', t.saved, true);
                    openChar(c);
                } })),
                el('div', { class: 'pn-msg', id: 'pn-rec-msg' }),
                el('div', { class: 'pn-section' }, el('h3', { text: t.pending }),
                    (r.recoveries || []).length === 0 ? el('div', { class: 'pn-empty', text: t.no_results }) :
                        r.recoveries.map((rec) => el('div', { class: 'pn-variant' },
                            el('div', { class: 'pn-item-sub', text: `#${rec.id} · ${rec.status} · ${fmtDate(rec.created_at)} · ${rec.reason}` }),
                            rec.status === 'aguardando' ? el('button', { class: 'btn btn-danger btn-sm', text: t.cancel_rec, onclick: async () => {
                                const x = await call('cancelRecovery', rec.id);
                                if (x.error) return setMsg('pn-rec-msg', x.message, false);
                                openChar(c);
                            } }) : null))));
        };

        document.getElementById('pn-body').replaceChildren(
            el('div', { class: 'pn-col pn-list' },
                el('label', { class: 'field' }, t.find_char,
                    el('input', { type: 'text', placeholder: t.find_hint, onchange: (e) => search(e.target.value.trim()) })),
                results),
            el('div', { class: 'pn-col pn-main' }, detail));
    }

    // ------------------------------------------------------------------ Uniformes

    async function loadUniforms(selectId) {
        const res = await call('uniforms', P.org);
        if (!P) return;
        P.uniforms = res.uniforms || [];
        P.myModel = res.myModel || null;
        if (selectId) P.edit = formFrom(P.uniforms.find((u) => u.id === selectId));
        renderUniforms(res.message);
    }

    function formFrom(u) {
        if (!u) return { id: null, name: '', mode: 'lista', grades: [], min: null, max: null, active: true, models: [] };
        return { id: u.id, name: u.name, mode: u.auth_mode, grades: [...(u.grades || [])], min: u.grade_min, max: u.grade_max,
            active: u.active, models: u.models || [], bags: u.bags };
    }

    function renderUniforms(error) {
        const t = P.t;
        const list = el('div', { class: 'pn-col pn-list' },
            el('button', { class: 'btn btn-primary', text: t.new_uniform, onclick: () => { P.edit = formFrom(null); renderUniforms(); } }),
            P.uniforms.length === 0 ? el('div', { class: 'pn-empty', text: t.empty_uniforms }) : null,
            P.uniforms.map((u) => el('div', {
                class: `pn-item ${P.edit && P.edit.id === u.id ? 'selected' : ''}`,
                onclick: () => { P.edit = formFrom(u); renderUniforms(); },
            },
            el('div', { class: 'pn-item-title' }, u.name, ' ',
                el('span', { class: `badge ${u.active ? '' : 'badge-muted'}`, text: u.active ? t.active : t.inactive })),
            el('div', { class: 'pn-item-sub', text: `${t.authorized_for}: ${summary(u)}` }),
            el('div', { class: 'pn-item-sub', text: `${t.versions}: ${MODELS.map(([m, k]) => `${t[k]} ${u.models.includes(m) ? '✓' : '—'}`).join(' · ')} · ${t.bags_count}: ${u.bags}` }))));

        const main = el('div', { class: 'pn-col pn-main' }, error ? el('div', { class: 'pn-msg err', text: error }) : null,
            P.edit ? editor() : el('div', { class: 'pn-empty', text: t.guide }));

        document.getElementById('pn-body').replaceChildren(list, main);
    }

    function editor() {
        const t = P.t;
        const f = P.edit;
        const grades = org()?.grades || [];

        const summaryNode = el('div', { class: 'pn-summary' });
        const refreshSummary = () => {
            summaryNode.textContent = `${t.authorized_for}: ${summary({ auth_mode: f.mode, grades: f.grades, grade_min: f.min, grade_max: f.max }) || '—'}`;
        };

        const gradeArea = el('div');
        const drawGrades = () => {
            if (f.mode === 'faixa') {
                gradeArea.replaceChildren(el('div', { class: 'pn-row' },
                    el('label', { class: 'field' }, t.grade_min,
                        el('select', { onchange: (e) => { f.min = Number(e.target.value); refreshSummary(); } },
                            grades.map((g) => el('option', { value: g.level, text: `${g.level} — ${g.name}`, selected: Number(f.min) === g.level || undefined })))),
                    el('label', { class: 'field' }, t.grade_max,
                        el('select', { onchange: (e) => { f.max = e.target.value === '' ? null : Number(e.target.value); refreshSummary(); } },
                            el('option', { value: '', text: t.no_max }),
                            grades.map((g) => el('option', { value: g.level, text: `${g.level} — ${g.name}`, selected: Number(f.max) === g.level || undefined }))))));
                if (f.min === null || f.min === undefined) f.min = grades[0]?.level ?? 0;
            } else {
                gradeArea.replaceChildren(el('div', { class: 'pn-checks' }, grades.map((g) =>
                    el('label', { class: 'pn-check' },
                        el('input', { type: 'checkbox', checked: f.grades.includes(g.level), onchange: (e) => {
                            f.grades = e.target.checked ? [...f.grades, g.level] : f.grades.filter((x) => x !== g.level);
                            refreshSummary();
                        } }),
                        `${g.level} — ${g.name}`))));
            }
            refreshSummary();
        };
        drawGrades();

        const save = async () => {
            setMsg('pn-edit-msg', P.t.loading, true);
            const res = await call('saveUniform', { id: f.id, org: P.org, name: f.name, mode: f.mode, grades: f.grades, min: f.min, max: f.max, active: f.active });
            if (!P) return;
            if (res.error) return setMsg('pn-edit-msg', res.message, false);
            await loadUniforms(res.id);
            setMsg('pn-edit-msg', t.saved, true);
        };

        // Uma área por versão: cada botão só grava a versão do próprio modelo (D214).
        const versions = f.id ? el('div', { class: 'pn-section' },
            el('h3', { text: t.versions }),
            el('div', { class: 'pn-item-sub', text: t.capture_hint }),
            el('div', { class: 'pn-variants' }, MODELS.map(([model, key]) => {
                const has = f.models.includes(model);
                const mine = P.myModel === model;
                return el('div', { class: `pn-variant-card ${mine ? 'mine' : ''}` },
                    el('div', {}, el('b', { text: t[key] }), ' ',
                        el('span', { class: `badge ${has ? '' : 'badge-warn'}`, text: has ? '✓' : t.missing })),
                    el('div', { class: 'pn-item-sub', text: mine ? t.you_are : (key === 'female' ? t.need_female : t.need_male) }),
                    el('div', { class: 'pn-row' },
                        el('button', { class: 'btn btn-primary btn-sm', disabled: !mine || undefined,
                            text: key === 'female' ? t.capture_female : t.capture_male, onclick: async () => {
                            setMsg('pn-edit-msg', t.loading, true);
                            const res = await call('captureVariant', f.id, model);
                            if (!P) return;
                            if (res.error) return setMsg('pn-edit-msg', res.message, false);
                            await loadUniforms(f.id);
                            setMsg('pn-edit-msg', `${t.captured} (${t[key]})`, true);
                        } }),
                        has ? el('button', { class: 'btn btn-danger btn-sm', text: t.remove, onclick: async () => {
                            const res = await call('removeVariant', f.id, model);
                            if (res.error) return setMsg('pn-edit-msg', res.message, false);
                            await loadUniforms(f.id);
                        } }) : null));
            }))) : null;

        // Excluir: só uniformes que nunca tiveram bolsa entregue; pede um segundo clique.
        let armed = false;
        const del = f.id ? el('button', { class: 'btn btn-danger', text: t.delete_uniform, title: t.delete_hint, onclick: async (e) => {
            if (!armed) { armed = true; e.target.textContent = t.confirm_delete; setTimeout(() => { armed = false; if (e.target.isConnected) e.target.textContent = t.delete_uniform; }, 4000); return; }
            const res = await call('deleteUniform', f.id);
            if (!P) return;
            if (res.error) return setMsg('pn-edit-msg', res.message, false);
            P.edit = null;
            await loadUniforms();
            setMsg('pn-edit-msg', t.deleted, true);
        } }) : null;

        return el('div', { class: 'pn-main' },
            el('h2', { text: f.id ? `${t.edit}: ${f.name}` : t.new_uniform }),
            el('label', { class: 'field' }, t.name, el('input', { type: 'text', value: f.name, maxlength: 100, oninput: (e) => { f.name = e.target.value; } })),
            el('label', { class: 'pn-switch' },
                el('input', { type: 'checkbox', checked: f.mode === 'faixa', onchange: (e) => { f.mode = e.target.checked ? 'faixa' : 'lista'; drawGrades(); } }),
                t.higher_ranks),
            el('div', { class: 'pn-item-sub', text: f.mode === 'faixa' ? t.mode_range : t.mode_list }),
            gradeArea,
            summaryNode,
            el('label', { class: 'pn-switch' },
                el('input', { type: 'checkbox', checked: f.active !== false, onchange: (e) => { f.active = e.target.checked; } }), t.active),
            el('div', { class: 'pn-row' },
                el('button', { class: 'btn btn-primary', text: t.save, onclick: save }),
                el('button', { class: 'btn btn-secondary', text: t.cancel, onclick: () => { P.edit = null; renderUniforms(); } }),
                del),
            el('div', { class: 'pn-msg', id: 'pn-edit-msg' }),
            versions);
    }

    // ------------------------------------------------------------------ Emissão

    async function loadIssue() {
        const t = P.t;
        const [res, stashes] = await Promise.all([call('uniforms', P.org), call('stashes', P.org)]);
        if (!P) return;
        const usable = (res.uniforms || []).filter((u) => u.active && u.models.length > 0);
        const list = Array.isArray(stashes) ? stashes : [];

        const form = { uniform: usable[0]?.id, qty: 1, stash: list[0]?.id || '' };
        document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-main' },
            el('div', { class: 'pn-row' },
                el('label', { class: 'field' }, t.uniform,
                    el('select', { onchange: (e) => { form.uniform = Number(e.target.value); } },
                        usable.map((u) => el('option', { value: u.id, text: u.name })))),
                el('label', { class: 'field' }, `${t.quantity} (1–${P.data.maxBatch})`,
                    el('input', { type: 'number', min: 1, max: P.data.maxBatch, value: 1, onchange: (e) => { form.qty = Number(e.target.value); } })),
                el('label', { class: 'field' }, t.stash,
                    list.length > 0
                        ? el('select', { onchange: (e) => { form.stash = e.target.value; } }, list.map((s) => el('option', { value: s.id, text: `${s.label} (${s.id})` })))
                        : el('input', { type: 'text', placeholder: t.no_stash, oninput: (e) => { form.stash = e.target.value.trim(); } }))),
            usable.length === 0 ? el('div', { class: 'pn-empty', text: t.empty_uniforms }) : null,
            el('div', { class: 'pn-row' },
                el('button', { class: 'btn btn-primary', text: t.issue_btn, disabled: usable.length === 0 || undefined, onclick: async () => {
                    setMsg('pn-issue-msg', t.loading, true);
                    const r = await call('issue', form.uniform, form.qty, form.stash);
                    if (r.error) return setMsg('pn-issue-msg', r.message, false);
                    setMsg('pn-issue-msg', t.issued.replace('%d', r.result.delivered).replace('%r', r.result.requested).replace('%f', r.result.failed), r.result.failed === 0);
                } })),
            el('div', { class: 'pn-msg', id: 'pn-issue-msg' })));
    }

    // ------------------------------------------------------------------ Bolsas

    const STATUS = () => ({ em_estoque: P.t.in_stock, em_circulacao: P.t.circulating, desconhecida: P.t.unknown });
    const LOC = { stash: 'Baú', player: 'Jogador', chao: 'No chão', drop: 'Drop' };

    async function loadBags() {
        const t = P.t;
        P.bagFilter = P.bagFilter || { status: '', search: '' };
        const res = await call('bags', P.org, P.bagFilter);
        if (!P) return;
        if (res.error) return document.getElementById('pn-body').replaceChildren(el('div', { class: 'pn-col pn-msg err', text: res.message }));

        const counts = Object.fromEntries((res.counts || []).map((c) => [c.status, c.n]));
        const filters = el('div', { class: 'pn-row' },
            el('label', { class: 'field' }, t.status,
                el('select', { onchange: (e) => { P.bagFilter.status = e.target.value; loadBags(); } },
                    [['', t.all], ['em_estoque', t.in_stock], ['em_circulacao', t.circulating], ['chao', t.ground], ['desconhecida', t.unknown], ['duplicada', t.duplicated]]
                        .map(([v, l]) => el('option', { value: v, text: l, selected: P.bagFilter.status === v || undefined })))),
            el('label', { class: 'field' }, t.search,
                el('input', { type: 'text', value: P.bagFilter.search, placeholder: 'UB-', onchange: (e) => { P.bagFilter.search = e.target.value; loadBags(); } })));

        const chips = el('div', { class: 'pn-chips' }, Object.entries(STATUS()).map(([k, l]) => el('span', { class: 'pn-chip' }, `${l}: `, el('b', { text: String(counts[k] || 0) }))));

        const rows = (res.bags || []).map((b) => el('tr', { onclick: () => history(b.bag_id) },
            el('td', { class: 'mono', text: b.bag_id }),
            el('td', { text: b.uniform }),
            el('td', {}, STATUS()[b.status] || b.status, b.flagged_duplicate ? el('span', { class: 'badge badge-warn', text: t.duplicated }) : null),
            el('td', { text: LOC[b.location_type] || b.location_type || '—' }),
            el('td', { text: `${fmtDate(b.last_activity_at)} (${b.last_activity_kind || '—'})` })));

        document.getElementById('pn-body').replaceChildren(
            el('div', { class: 'pn-col pn-main' }, filters, chips,
                rows.length === 0 ? el('div', { class: 'pn-empty', text: t.no_bags }) :
                    el('table', { class: 'pn-table' },
                        el('thead', {}, el('tr', {}, [t.bag_id, t.uniform, t.status, t.location, t.last_activity].map((h) => el('th', { text: h })))),
                        el('tbody', {}, rows))),
            el('div', { class: 'pn-col pn-list', id: 'pn-history', style: 'border-left:1px solid var(--color-border);border-right:none' },
                el('div', { class: 'pn-empty', text: t.history })));
    }

    async function history(bagId) {
        const t = P.t;
        const res = await call('bagHistory', bagId);
        const box = document.getElementById('pn-history');
        if (!box || !P) return;
        if (res.error) return box.replaceChildren(el('div', { class: 'pn-msg err', text: res.message }));
        box.replaceChildren(
            el('h3', { class: 'mono', text: bagId }),
            el('div', { class: 'pn-section' }, el('h3', { text: t.slots }),
                (res.slots || []).length === 0 ? el('div', { class: 'pn-empty', text: t.empty }) :
                    res.slots.map((s) => el('div', { class: 'pn-item-sub', text: `${s.slot}. ${s.storedBy} — ${fmtDate(s.storedAt)}${s.isUniform ? ' (farda)' : ''}` }))),
            el('div', { class: 'pn-section' }, el('h3', { text: t.history }),
                (res.history || []).map((h) => el('div', { class: 'pn-item-sub', text: `${fmtDate(h.created_at)} · ${h.category}/${h.action}${h.actor_name ? ' · ' + h.actor_name : ''}` }))));
    }

    // ------------------------------------------------------------------ Mensagens do cliente

    window.addEventListener('message', (event) => {
        const msg = event.data || {};
        if (msg.action === 'panelOpen') {
            P = { data: msg.data, t: msg.locale, org: msg.data.orgs[0]?.name, tab: 'uniforms', uniforms: [], edit: null };
            if (/^#[0-9a-fA-F]{6}$/.test(msg.data.color || '')) document.documentElement.style.setProperty('--color-primary', msg.data.color);
            shell();
            load();
        } else if (msg.action === 'panelClose') {
            document.getElementById('panel-root').replaceChildren();
            P = null;
        } else if (msg.action === 'panelHide') {
            const b = document.getElementById('pn-backdrop');
            if (b) b.style.display = 'none';
        } else if (msg.action === 'panelShow') {
            const b = document.getElementById('pn-backdrop');
            if (b) b.style.display = '';
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && P && !EMBED) close();
    });

    // Embutido no mri_Qadmin (web/plugin.html): a própria página pede os dados iniciais.
    const EMBED = document.body && document.body.dataset.embed === '1';
    if (EMBED) {
        // Protocolo de plugin do mri_Qadmin: avisa que a página está pronta; ele responde com
        // mri-plugin/init (cor do painel). Reaberturas chegam como mri-plugin/navigate.
        window.addEventListener('message', (event) => {
            const msg = event.data || {};
            if ((msg.type === 'mri-plugin/init' || msg.type === 'mri-plugin/theme-changed')
                && /^#[0-9a-fA-F]{6}$/.test(msg.accentColor || '')) {
                document.documentElement.style.setProperty('--color-primary', msg.accentColor);
            } else if (msg.type === 'mri-plugin/navigate' && P) {
                load();
            }
        });
        window.parent.postMessage({ type: 'mri-plugin/ready' }, '*');

        nui('panelBootstrap').then((res) => {
            if (!res || res.error) {
                document.getElementById('panel-root').replaceChildren(el('div', { class: 'pn-col pn-msg err', text: (res && res.message) || 'Sem acesso.' }));
                return;
            }
            P = { data: res.data, t: res.locale, org: res.data.orgs[0]?.name, tab: 'uniforms', uniforms: [], edit: null };
            if (/^#[0-9a-fA-F]{6}$/.test(res.data.color || '')) document.documentElement.style.setProperty('--color-primary', res.data.color);
            shell();
            load();
        });
    }
})();
