import { createClient } from "@supabase/supabase-js";
import { ai_scoring } from "../_actions/ai_scoring";
import { store_in_database } from "../_actions/store_in_encrypted_database";

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

export async function POST(request) {
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

    const formData = await request.formData();

    const category = formData.get('category');
    const location = formData.get('location');
    const description = formData.get('description');
    const public_key = formData.get('public_key');
    const userId = formData.get('userId');
    const file = formData.get('file');

    // Make file optional for now
    if (!category || !location || !description || !public_key) {
      return new Response(JSON.stringify({ error: 'Invalid input - missing required fields' }), { 
        status: 400,
        headers: corsHeaders
      });
    }

    console.log('Received report data:', {
      category,
      location,
      description: description.substring(0, 50) + '...', // Log first 50 chars
      public_key: public_key.substring(0, 20) + '...', // Log first 20 chars
      userId,
      hasFile: !!file
    });

    //ai validation
    const result = await ai_scoring(formData);
    if (!result) {
      return new Response(JSON.stringify({ error: 'AI scoring failed' }), { 
        status: 500,
        headers: corsHeaders
      });
    }

    //store in db
    const { data, error: dbError } = await store_in_database(formData, result, token);

    if (dbError) {
      console.error('Database error:', dbError);
      return new Response(JSON.stringify({ error: 'Failed to store report in database' }), { 
        status: 500,
        headers: corsHeaders
      });
    }

    return new Response(JSON.stringify({ 
      message: 'Report submitted successfully',
      data: data 
    }), { 
      status: 200,
      headers: corsHeaders
    });

  } catch (error) {
    console.error("Error in POST /api/report:", error);
    return new Response(JSON.stringify({ error: 'Internal Server Error', details: error.message }), { 
      status: 500,
      headers: corsHeaders
    });
  }
}
