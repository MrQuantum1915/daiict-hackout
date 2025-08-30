'use server'
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

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
    const del_credit = 0;
    if (incident_probability > 0.6) {
        del_credit=100;
    }

    const { data, error: dbError } = await supabase
        .from('reports')
        .insert([
            {
                reporter_uuid: user.id,
                category: category,
                status: 'Pending NGO Verification',
                location: location,
                ai_score: {
                    accuracy_score: accuracy_score,
                    incident_probability: incident_probability,
                    analysis_summary: analysis_summary
                }
            }
        ]);

    //store the image files
    const images = formData.getAll('images');
    const imageUploads = images.map(async (image) => {
        const { data, error } = await supabase.storage.from('images').upload(`public/${user.id}/${Date.now()}_${image.name}`, image);
        if (error) {
            console.log(error);
            return null;
        }
        return data.Key;
    });

    const uploadedImageKeys = await Promise.all(imageUploads);

    if (dbError) {
        console.log(dbError);
        return { error: dbError };
    }
    return { data: data };
}