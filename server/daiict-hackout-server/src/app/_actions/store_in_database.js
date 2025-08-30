'use server'
import { createClient_server } from "@/utils/supabase/supabaseServer"

export async function store_in_database(formData, result, token) {
    if (!token) {
        return { error: "error storing in db" }
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
        return { error: "error storing in db" }
    }

    const { accuracy_score, incident_probability, analysis_summary } = result;
    const category = formData.get('category');
    const location = formData.get('location');
    const { data, error: dbError } = await supabase
        .from('reports')
        .insert([
            {
                user_id: user.id,
                report_data: formData.get('reportData'),
                file: formData.get('file'),
            }
        ]);

    if (dbError) {
        console.log(dbError);
        return { error: dbError };
    }
    return { data: data };
}