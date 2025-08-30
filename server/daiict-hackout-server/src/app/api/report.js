import { createClient } from "@supabase/supabase-js";
import { ai_scoring } from "../_actions/ai_scoring";
import { store_in_database } from "../_actions/store_in_database";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

export async function POST(request) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.split(' ')[1];

    if (!token) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const formData = await request.formData();

    const userId = formData.get('userId');
    const reportData = formData.get('reportData');
    const file = formData.get('file');

    if (!userId || !reportData || !file) {
      return new Response("Invalid input", { status: 400 });
    }


    //ai validation
    const result = await ai_scoring(formData);
    if (!result) {
      return new Response("AI scoring failed", { status: 500 });
    }

    //store in db
    const { data, error: dbError } = await store_in_database(formData, result, token);

    if (dbError) {
      return new Response("Failed to store report in database", { status: 500 });
    }


    return new Response("Report submitted successfully", { status: 200 });

  } catch (error) {
    console.error("Error:", error);
    return new Response("Internal Server Error", { status: 500 });
  }
}
