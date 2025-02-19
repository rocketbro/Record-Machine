import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import AWS from "npm:aws-sdk"

// Validate the request payload
interface SignUrlRequest {
  objectPath: string;      // The S3 object path to generate a signed URL for
  expiresIn?: number;      // Optional: URL expiration time in seconds (default: 1 hour)
}

function validateRequest(body: any): SignUrlRequest {
  if (!body.objectPath || typeof body.objectPath !== 'string') {
    throw new Error('objectPath is required and must be a string');
  }
  
  // Parse expiresIn as a number, default to 3600 if invalid
  let expiresIn = 3600;
  if (body.expiresIn) {
    const parsed = parseInt(body.expiresIn, 10);
    if (!isNaN(parsed) && parsed > 0) {
      expiresIn = parsed;
    }
  }
  
  return {
    objectPath: body.objectPath,
    expiresIn
  };
}

function formatPEM(key: string): string {
  // Remove any quotes and convert literal \n to actual newlines
  key = key.replace(/^["']|["']$/g, '')
    .replace(/\\n/g, '\n')
    .replace(/\n+/g, '\n')
    .trim();
  
  // Remove any existing formatting and split into 64-char lines
  const cleaned = key.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '')
    .replace(/[\n\r\s]/g, '');
  const lines = cleaned.match(/.{1,64}/g) || [];
  
  return '-----BEGIN PRIVATE KEY-----\n' 
    + lines.join('\n') 
    + '\n-----END PRIVATE KEY-----';
}

serve(async (req) => {
  try {
    // Get environment variables
    const privateKey = formatPEM(Deno.env.get("CLOUDFRONT_PRIVATE_KEY") || '');
    const keyPairId = Deno.env.get("CLOUDFRONT_KEY_PAIR_ID");
    const distributionDomain = Deno.env.get("CLOUDFRONT_DOMAIN");
    
    console.log("Key Pair ID:", keyPairId);
    console.log("Distribution Domain:", distributionDomain);
    console.log("Private Key Length:", privateKey.length);
    
    const missing = [];
    if (!privateKey) missing.push("CLOUDFRONT_PRIVATE_KEY");
    if (!keyPairId) missing.push("CLOUDFRONT_KEY_PAIR_ID");
    if (!distributionDomain) missing.push("CLOUDFRONT_DOMAIN");
    
    if (missing.length > 0) {
      throw new Error(`Missing required environment variables: ${missing.join(", ")}`);
    }
    
    // Parse and validate request
    const requestBody = await req.json();
    console.log("Request body:", JSON.stringify(requestBody));
    const { objectPath, expiresIn } = validateRequest(requestBody);
    console.log("Validated request - objectPath:", objectPath, "expiresIn:", expiresIn);
    
    // Calculate expiration time (more safely)
    const now = Math.floor(Date.now() / 1000); // Current time in seconds
    const expires = now + expiresIn;
    console.log("Current time:", now, "Expires at:", expires);
    
    // Create CloudFront signer
    const signer = new AWS.CloudFront.Signer(keyPairId, privateKey);
    
    // Generate signed URL
    const url = `https://${distributionDomain}/${objectPath}`;
    console.log("Base URL to sign:", url);
    
    const signedUrl = await new Promise((resolve, reject) => {
      try {
        signer.getSignedUrl({
          url,
          expires // Pass as number, not Date
        }, (err, url) => {
          if (err) {
            console.error("Signing error:", err);
            reject(err);
          } else {
            console.log("Successfully generated signed URL");
            resolve(url);
          }
        });
      } catch (error) {
        console.error("Error in signing process:", error);
        reject(error);
      }
    });
    
    return new Response(
      JSON.stringify({ signedUrl }),
      {
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
        },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Function error:", error);
    return new Response(
      JSON.stringify({ 
        error: error.message,
        stack: error.stack,
        details: "Error occurred while generating signed URL"
      }),
      {
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
        },
        status: 400,
      }
    );
  }
})
