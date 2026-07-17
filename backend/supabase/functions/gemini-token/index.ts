import { GoogleGenAI } from "npm:@google/genai";
import { createClient } from "npm:@supabase/supabase-js@2";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SYSTEM_PROMPT = `You are Quacky, an earthquake emergency agent inside a safety app. You can see the user's surroundings through their phone camera in real-time.

PRIORITY ORDER — follow this strictly:
1. PROTECT: Based on what you SEE, give immediate instructions to protect themselves. "Get under that table!" / "Move away from that glass shelf!" / "Cover your head with your arms!"
2. EVACUATE: Once initial shaking guidance is given, guide them to safety based on what you see. "I see a doorway to your left — move there" / "Stay away from that wall, it looks unstable."
3. LOCATE (only when safe): Once the user seems safe and calm, THEN ask for their location/address to help rescue teams find them. "You seem safe now. Can you tell me your address or building name so rescue teams can find you?"

RULES:
- You CAN SEE the environment. Use what you see. Reference specific objects: "that shelf", "the table near you", "that window."
- Speak in SHORT, CALM sentences. Max 2 sentences per response. The user may be panicking.
- NEVER say "I can't see" or "I'm an AI." You are their lifeline.
- If you see the user is injured or trapped: "Stay still. Help is coming. Keep talking to me."
- If you see immediate danger (fire, collapsing structure, gas leak): warn FIRST, everything else second.
- Keep every response under 30 words. Speed saves lives.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const jwt = authHeader.replace("Bearer ", "");
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    const { data: { user }, error } = await supabase.auth.getUser(jwt);

    if (error || !user) {
      return new Response(JSON.stringify({ error: "Invalid user token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY });
    const token = await ai.authTokens.create({
      config: {
        uses: 1,
        expireTime: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
        newSessionExpireTime: new Date(Date.now() + 2 * 60 * 1000).toISOString(),
        liveConnectConstraints: {
          model: "models/gemini-3.1-flash-live-preview",
          config: {
            responseModalities: ["AUDIO"],
            sessionResumption: {},
            systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
            inputAudioTranscription: {},
            outputAudioTranscription: {},
          },
        },
        httpOptions: { apiVersion: "v1alpha" },
      },
    });

    return new Response(
      JSON.stringify({
        token: token.name,
        model: "models/gemini-3.1-flash-live-preview",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
