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
    const description = formData.get('description'); // This is encrypted
    const public_key = formData.get('public_key');

    // Calculate credits based on AI analysis
    let credits_earned = 0;
    if (incident_probability > 0.3) {
        credits_earned = 100;
    } else {
        credits_earned = -50;
    }

    // Store encrypted report in reports table
    const { data: reportData, error: reportError } = await supabase
        .from('reports')
        .insert([
            {
                reporter_uuid: user.id,
                category: category,
                status: 'Pending NGO Verification',
                location: location,
                description: description, // Encrypted description
                credits_earned: credits_earned,
                ai_score: {
                    accuracy_score: accuracy_score,
                    incident_probability: incident_probability,
                    analysis_summary: analysis_summary
                },
                public_key: public_key
            }
        ])
        .select()
        .single();

    if (reportError) {
        console.log('Report storage error:', reportError);
        return { error: reportError };
    }

    // Store non-encrypted data in public_reports table for AI analysis
    const { data: publicData, error: publicError } = await supabase
        .from('public_reports')
        .insert([
            {
                category: category,
                status: 'Pending NGO Verification',
                location: location,
                description: `Report ID: ${reportData.report_id}`, // Reference to encrypted report
                ai_score: {
                    accuracy_score: accuracy_score,
                    incident_probability: incident_probability,
                    analysis_summary: analysis_summary
                }
            }
        ]);

    if (publicError) {
        console.log('Public report storage error:', publicError);
        // Don't fail the entire operation if public report fails
    }

    // Store the image file
    const file = formData.get('file');
    if (file) {
        try {
            const fileName = `reports/${user.id}/${Date.now()}_${file.name}`;
            const { data: uploadData, error: uploadError } = await supabase.storage
                .from('images')
                .upload(fileName, file);

            if (uploadError) {
                console.log('Image upload error:', uploadError);
            } else {
                // Update the report with image URL
                const imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
                await supabase
                    .from('reports')
                    .update({ image_url: imageUrl.data.publicUrl })
                    .eq('report_id', reportData.report_id);
            }
        } catch (uploadError) {
            console.log('Image upload error:', uploadError);
        }
    }

    // Update user credits
    try {
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('credits')
            .eq('user_uuid', user.id)
            .single();

        if (!userError && userData) {
            const newCredits = (userData.credits || 0) + credits_earned;
            await supabase
                .from('users')
                .update({ credits: newCredits })
                .eq('user_uuid', user.id);
        }
    } catch (creditError) {
        console.log('Credit update error:', creditError);
    }

    return { data: reportData };
}