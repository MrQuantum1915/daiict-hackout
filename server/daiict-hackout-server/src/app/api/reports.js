import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

// CORS headers for cross-origin requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Content-Type': 'application/json',
};

// Handle OPTIONS request for CORS preflight
export async function OPTIONS(request) {
  return new Response(null, {
    status: 200,
    headers: corsHeaders,
  });
}

export async function GET(request) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.split(' ')[1];

    if (!token) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: corsHeaders
      });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: corsHeaders
      });
    }

    // Get user's reports
    const { data: reports, error: reportsError } = await supabase
      .from('reports')
      .select('*')
      .eq('reporter_uuid', user.id)
      .order('report_id', { ascending: false });

    if (reportsError) {
      console.error('Reports fetch error:', reportsError);
      return new Response(JSON.stringify({ error: 'Failed to fetch reports' }), {
        status: 500,
        headers: corsHeaders
      });
    }

    return new Response(JSON.stringify({ reports }), {
      status: 200,
      headers: corsHeaders
    });

  } catch (error) {
    console.error("Error in GET /api/reports:", error);
    return new Response(JSON.stringify({ error: 'Internal Server Error', details: error.message }), {
      status: 500,
      headers: corsHeaders
    });
  }
}
