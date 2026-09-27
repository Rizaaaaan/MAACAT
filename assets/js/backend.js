/* ============================================================
   MAACAT backend bridge (lucky draw only)
   ------------------------------------------------------------
   Fill in SUPABASE_URL and SUPABASE_ANON_KEY below and every
   survey submission starts saving to one real, shared database
   with duplicate phone numbers blocked. Leave them blank and it
   keeps working exactly as it does today: saved to this browser
   only, for testing.

   Setup steps live in BACKEND.md. Short version: create a free
   Supabase project, paste supabase-schema.sql into its SQL
   editor and run it once, then copy two values from
   Settings → API into the two lines below.
   ============================================================ */

const SUPABASE_URL = '';        // e.g. 'https://abcdxyzcompany.supabase.co'
const SUPABASE_ANON_KEY = '';   // the "anon public" key, NOT the service_role key

const BACKEND_ENABLED = SUPABASE_URL.startsWith('https://') && SUPABASE_ANON_KEY.length > 20;

let _sb = null;
if (BACKEND_ENABLED && window.supabase) {
  _sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

const LOCAL_ENTRIES_KEY = 'maacat_entries_prototype';

function _cleanPhone(v){ return String(v || '').replace(/\D/g, ''); }

/* ============================================================
   Public API — the only thing the page calls.
   ============================================================ */
const MaacatBackend = {
  mode: BACKEND_ENABLED ? 'live' : 'local',

  async submitLuckyDraw(payload){
    const phone = _cleanPhone(payload.phone);

    if (BACKEND_ENABLED) {
      const { data, error } = await _sb.rpc('submit_lucky_draw', {
        p_phone: phone,
        p_age: payload.age,
        p_favourite_stall: payload.favouriteStall,
        p_why: payload.why,
        p_improve: payload.improve || null
      });
      if (error) { console.error('submitLuckyDraw', error); return { success:false, message:'Connection problem — try again.' }; }
      return data;
    }

    // Local fallback: same duplicate-phone rule, this browser only.
    let entries = [];
    try { entries = JSON.parse(localStorage.getItem(LOCAL_ENTRIES_KEY) || '[]'); } catch(e){}
    if(entries.some(e => e.phone === phone)){
      return { success:false, message:'You have already entered the lucky draw.' };
    }
    entries.push({ ...payload, phone, at:new Date().toISOString() });
    try { localStorage.setItem(LOCAL_ENTRIES_KEY, JSON.stringify(entries)); } catch(e){}
    return { success:true, message:"You've entered the lucky draw! Please vote MAACAT for the best team of the event." };
  }
};
