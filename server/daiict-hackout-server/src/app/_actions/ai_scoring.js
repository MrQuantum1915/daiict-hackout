'user server'
import { GoogleGenAI } from "@google/genai";
import { createPartFromFile } from "@google/genai"; // import method for file parts

const myApiKey = process.env.Gemini_API_Key;
const ai = new GoogleGenAI({ apiKey: myApiKey });

const systemInstruction = ` You are an AI system that analyzes images and videos submitted as incident reports in an environmental monitoring application. Your tasks are:
## 1. Image/Video Analysis  
- Examine the submitted media to detect relevant environmental incidents such as illegal dumping or poaching.  
- Use context clues, object recognition, and scene understanding to assess the content.  
## 2. Accuracy Scoring  
- Provide a quantitative percentage score (0% to 100%) representing the confidence level or accuracy that the reported incident shown in the media is genuine and matches the reported category.  
- Score should reflect your certainty based on image quality, clarity, orientation, and content relevance.  
## 3. Probability Validation  
- Output a probability value indicating the likelihood that the reported event is a true incident (not a false alert or benign).  
- Incorporate model confidence, contextual cues, and noise assessment as part of this probability.  
## 4. Output Format  
- Return a JSON object with fields:  
  - accuracy_score (percentage, float)  
  - incident_probability (probability between 0 and 1, float)  
  - analysis_summary (brief text explaining key factors influencing the score)  
## 5. Additional Requirements  
- Consider variations like lighting, angle, and potential obfuscations in media.  
- Be robust to false positives and differentiate subtle environmental signs.  
- Your output will be used upstream to trigger NGO verification and enforcement alerts.
`;

export async function ai_scoring(formdata) {
    try {
        const category = formdata.get('category');
        const location = formdata.get('location');
        const file = formdata.get('file');
        
        // If no file is provided, return a default analysis
        if (!file) {
            console.log('No file provided for AI analysis, using default scoring');
            return {
                accuracy_score: 50.0,
                incident_probability: 0.5,
                analysis_summary: "No image provided for analysis. Default scoring applied."
            };
        }

        const filePart = createPartFromFile(file, file.type);

        const response = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: {
                role: "user",
                parts: [
                    { text: `Analyze this media for environmental incident report: category: ${category}, location: ${location}` },
                    filePart
                ],
                config: {
                    systemInstruction,
                    responseMimeType: "application/json",
                    responseSchema: {
                        type: "object",
                        properties: {
                            accuracy_score: { type: "number" },
                            incident_probability: { type: "number" },
                            analysis_summary: { type: "string" },
                        },
                        requiredProperties: ["accuracy_score", "incident_probability", "analysis_summary"],
                        propertyOrdering: ["accuracy_score", "incident_probability", "analysis_summary"]
                    }
                }
            }
        });

        const responseData = response.response;
        const content = responseData.candidates[0].content.parts[0].text;
        
        // Parse the JSON response properly
        let parsedContent;
        try {
            parsedContent = typeof content === 'string' ? JSON.parse(content) : content;
        } catch (parseError) {
            console.error('Error parsing AI response:', parseError);
            // Return default values if parsing fails
            return {
                accuracy_score: 50.0,
                incident_probability: 0.5,
                analysis_summary: "AI analysis failed, default scoring applied."
            };
        }

        return {
            accuracy_score: parsedContent.accuracy_score || 50.0,
            incident_probability: parsedContent.incident_probability || 0.5,
            analysis_summary: parsedContent.analysis_summary || "AI analysis completed with default values."
        };
    } catch (error) {
        console.error('AI scoring error:', error);
        // Return default values if AI scoring fails
        return {
            accuracy_score: 50.0,
            incident_probability: 0.5,
            analysis_summary: "AI analysis failed due to error, default scoring applied."
        };
    }
}
