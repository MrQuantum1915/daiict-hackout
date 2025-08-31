'use server'
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

export async function store_in_database(formData, result, token) {
    try {
        if (!token) {
            console.error('No token provided for database storage');
            return { error: "No authentication token provided" }
        }

        const { data: { user }, error } = await supabase.auth.getUser(token);
        if (error || !user) {
            console.error('User authentication failed:', error);
            return { error: "User authentication failed" }
        }

        console.log('Storing report for user:', user.id);

        const { accuracy_score, incident_probability, analysis_summary } = result;
        const category = formData.get('category');
        const location = formData.get('location');
        const description = formData.get('description'); // This is encrypted
        const public_key = formData.get('public_key');

        console.log('Report data:', {
            category,
            location,
            descriptionLength: description ? description.length : 0,
            hasPublicKey: !!public_key,
            aiScore: accuracy_score,
            probability: incident_probability
        });

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
            console.error('Report storage error:', reportError);
            return { error: reportError };
        }

        console.log('Report stored successfully with ID:', reportData.report_id);

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
            console.error('Public report storage error:', publicError);
            // Don't fail the entire operation if public report fails
        }

        // Store the image file
        const file = formData.get('file');
        if (file) {
            try {
                const fileName = `reports/${user.id}/${Date.now()}_${file.name}`;
                console.log('Uploading file:', fileName);
                
                const { data: uploadData, error: uploadError } = await supabase.storage
                    .from('images')
                    .upload(fileName, file);

                if (uploadError) {
                    console.error('Image upload error:', uploadError);
                } else {
                    // Update the report with image URL
                    const imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
                    await supabase
                        .from('reports')
                        .update({ image_url: imageUrl.data.publicUrl })
                        .eq('report_id', reportData.report_id);
                    
                    console.log('Image uploaded successfully:', imageUrl.data.publicUrl);
                }
            } catch (uploadError) {
                console.error('Image upload error:', uploadError);
            }
        } else {
            console.log('No file provided for upload');
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
                
                console.log('User credits updated:', newCredits);
            }
        } catch (creditError) {
            console.error('Credit update error:', creditError);
        }

        console.log('Database storage completed successfully');
        return { data: reportData };
    } catch (error) {
        console.error('Database storage error:', error);
        return { error: error.message || 'Unknown database error' };
    }
}