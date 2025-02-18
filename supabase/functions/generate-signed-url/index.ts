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
  
  return {
    objectPath: body.objectPath,
    expiresIn: body.expiresIn || 3600 // Default to 1 hour
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
    
    const missing = [];
    if (!privateKey) missing.push("CLOUDFRONT_PRIVATE_KEY");
    if (!keyPairId) missing.push("CLOUDFRONT_KEY_PAIR_ID");
    if (!distributionDomain) missing.push("CLOUDFRONT_DOMAIN");
    
    if (missing.length > 0) {
      throw new Error(`Missing required environment variables: ${missing.join(", ")}`);
    }
    
    // Parse and validate request
    const { objectPath, expiresIn } = validateRequest(await req.json());
    
    // Calculate expiration time
    const expires = Math.floor(Date.now() / 1000) + expiresIn;
    
    // Create CloudFront signer
    const signer = new AWS.CloudFront.Signer(keyPairId, privateKey);
    
    // Generate signed URL
    const url = `https://${distributionDomain}/${objectPath}`;
    const signedUrl = await new Promise((resolve, reject) => {
      signer.getSignedUrl({
        url,
        expires
      }, (err, url) => {
        if (err) reject(err);
        else resolve(url);
      });
    });
    
    return new Response(
      JSON.stringify({ signedUrl }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
})
