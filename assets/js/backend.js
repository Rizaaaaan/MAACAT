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

const SUPABASE_URL = 'https://gnpswfsreebzevkpyxrf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImducHN3ZnNyZWViemV2a3B5eHJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2NTYyMzEsImV4cCI6MjEwNjIzMjIzMX0.HqebMgOOpJd9F4sR-nbGVaN7WHHdmPTcAJ7Mg32Z3FA';

const BACKEND_ENABLED = SUPABASE_URL.startsWith('https://') && SUPABASE_ANON_KEY.length > 20;

// The client is created lazily, on first use, rather than at page-load —
// if the Supabase library is still loading (or fails to load) at the
// instant this file runs, grabbing window.supabase too early would leave
// _sb permanently null even once the library is ready a moment later.
let _sb = null;
function _getClient(){
  if (_sb) return _sb;
  if (window.supabase && typeof window.supabase.createClient === 'function') {
    _sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }
  return _sb;
}

const LOCAL_ENTRIES_KEY = 'maacat_entries_prototype';
const CONNECTION_PROBLEM = { success:false, message:'Connection problem — check your internet and try again.' };

function _cleanPhone(v){ return String(v || '').replace(/\D/g, ''); }

/* ============================================================
   Public API — the only thing the page calls.
   ============================================================ */
const MaacatBackend = {
  mode: BACKEND_ENABLED ? 'live' : 'local',

  async submitLuckyDraw(payload){
    const phone = _cleanPhone(payload.phone);

    if (BACKEND_ENABLED) {
      // Wrapped in try/catch: a slow CDN, an ad blocker, or any other
      // reason the Supabase library or network call fails should show
      // the person a message, never leave the submit button hanging.
      try {
        const client = _getClient();
        if (!client) return CONNECTION_PROBLEM;

        const { data, error } = await client.rpc('submit_lucky_draw', {
          p_phone: phone,
          p_age: payload.age,
          p_favourite_stall: payload.favouriteStall,
          p_why: payload.why,
          p_improve: payload.improve || null
        });
        if (error) { console.error('submitLuckyDraw', error); return CONNECTION_PROBLEM; }
        return data;
      } catch (err) {
        console.error('submitLuckyDraw threw', err);
        return CONNECTION_PROBLEM;
      }
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
