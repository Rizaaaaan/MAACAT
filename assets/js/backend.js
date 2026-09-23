/* ============================================================
   MAACAT backend bridge
   ------------------------------------------------------------
   Fill in SUPABASE_URL and SUPABASE_ANON_KEY below and every
   stall's device — plus the main site — starts sharing one real
   database. Leave them blank and everything keeps working
   exactly as it does today: local to whatever device you're on.

   Setup steps live in BACKEND.md → "Fastest path: Supabase".
   Short version: create a free Supabase project, paste
   supabase-schema.sql into its SQL editor and run it once, then
   copy two values from Settings → API into the two lines below.
   ============================================================ */

const SUPABASE_URL = '';        // e.g. 'https://abcdxyzcompany.supabase.co'
const SUPABASE_ANON_KEY = '';   // the "anon public" key, NOT the service_role key

const BACKEND_ENABLED = SUPABASE_URL.startsWith('https://') && SUPABASE_ANON_KEY.length > 20;

let _sb = null;
if (BACKEND_ENABLED && window.supabase) {
  _sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

const LOCAL_STAMPS_KEY = 'maacat_stamps_prototype';
const LOCAL_ENTRIES_KEY = 'maacat_entries_prototype';

// Only used in local (unconfigured) mode. Change these before
// relying on them for anything real — see README "Running the
// stamp card on the day".
const DEMO_PINS = { "01":"1101", "02":"1102", "03":"1103", "04":"1104", "05":"1105", "06":"1106" };

function _cleanPhone(v){ return String(v || '').replace(/\D/g, ''); }

function _readLocalStamps(){
  try { return JSON.parse(localStorage.getItem(LOCAL_STAMPS_KEY) || '{}'); } catch(e){ return {}; }
}
function _writeLocalStamps(data){
  try { localStorage.setItem(LOCAL_STAMPS_KEY, JSON.stringify(data)); } catch(e){}
}

/* ============================================================
   Public API — the only thing index.html / staff.html call.
   Every method returns the same shape whether it hit Supabase
   or the local fallback, so the UI code never needs to know
   which mode it's in.
   ============================================================ */
const MaacatBackend = {
  mode: BACKEND_ENABLED ? 'live' : 'local',

  async verifyPin(stallId, pin){
    if (BACKEND_ENABLED) {
      const { data, error } = await _sb.rpc('verify_stall_pin', { p_stall_id: stallId, p_pin: pin });
      if (error) { console.error('verifyPin', error); return false; }
      return data === true;
    }
    return DEMO_PINS[stallId] === pin;
  },

  async grantStamp(stallId, phoneRaw){
    const phone = _cleanPhone(phoneRaw);
    if (BACKEND_ENABLED) {
      const { data, error } = await _sb.rpc('grant_stamp', { p_stall_id: stallId, p_phone: phone });
      if (error) { console.error('grantStamp', error); return { success:false, message:'Connection problem — try again.' }; }
      return data;
    }
    const all = _readLocalStamps();
    if(!all[phone]) all[phone] = {};
    if(all[phone][stallId]){
      return { success:false, message:'Already stamped for this stall.' };
    }
    all[phone][stallId] = true;
    _writeLocalStamps(all);
    const count = Object.keys(all[phone]).length;
    return { success:true, stamp_count:count, full_card: count === 6 };
  },

  async getStatus(phoneRaw){
    const phone = _cleanPhone(phoneRaw);
    if (BACKEND_ENABLED) {
      const { data, error } = await _sb.rpc('get_stamp_status', { p_phone: phone });
      if (error) { console.error('getStatus', error); return { stamps:[], stamp_count:0, full_card:false }; }
      return data;
    }
    const owned = _readLocalStamps()[phone] || {};
    const stamps = Object.keys(owned).filter(k => owned[k]);
    return { stamps, stamp_count: stamps.length, full_card: stamps.length === 6 };
  },

  async submitLuckyDraw(payload){
    const phone = _cleanPhone(payload.phone);
    if (BACKEND_ENABLED) {
      const { data, error } = await _sb.rpc('submit_lucky_draw', {
        p_phone: phone,
        p_age: payload.age,
        p_favourite_stall: payload.favouriteStall,
        p_why: payload.why,
        p_improve: payload.improve || null,
        p_source: payload.source || null
      });
      if (error) { console.error('submitLuckyDraw', error); return { success:false, message:'Connection problem — try again.' }; }
      return data;
    }
    const status = await this.getStatus(phone);
    if(!status.full_card){
      return { success:false, message:`This number has ${status.stamp_count} of 6 stamps. Visit the remaining stalls, then come back.` };
    }
    let entries = [];
    try { entries = JSON.parse(localStorage.getItem(LOCAL_ENTRIES_KEY) || '[]'); } catch(e){}
    if(entries.some(e => e.phone === phone)){
      return { success:false, message:'This mobile number has already entered the lucky draw.' };
    }
    entries.push({ ...payload, phone, at:new Date().toISOString() });
    try { localStorage.setItem(LOCAL_ENTRIES_KEY, JSON.stringify(entries)); } catch(e){}
    return { success:true, message:"You're in! Good luck." };
  }
};
