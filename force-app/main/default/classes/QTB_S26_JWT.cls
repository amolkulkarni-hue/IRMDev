/*****************************************************************************************************
* @File Name:   QTB_S26_JWT 
* @Author:      Virtusa
* @Developer:   Suresh Uppala
* @Story Number : #471
* @Description:Generating the JWT token based on this token we are communicating with Fire Base Application 
-------------------------------------------------------------------------------------------------
* Version          Developer          Date               Description
*  1.0              Suresh U      	01/05/2021          Initial Creation                                                      
**************************************************************************************************/

public class QTB_S26_JWT {
    public static boolean throwExplicitException = false;
    public static final String QTBS26JWT = QTB_S26_JWT.class.getName();
    //Header Details
    public class JWTHeader {
        public String alg{get; set;}
        public String type{get; set;} 
        public String kid{get; set;}
    }
    
    // Body Details
    public class JWTBody {
        public String iss{get; set;}
        public String sub{get; set;}
        public String aud{get; set;}
		public Integer iat{get; set;}
		public Integer exp{get; set;}
    }    
    // Generating the JWT Token
    public Static String generateJWT(){
        // Get all custommetadata with respect to developername ='RS256'
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            QTB_S26_RS256_JWT__mdt rs=[Select id,DeveloperName,QTB_S26_Alg__c,QTB_S26_Aud__c,QTB_S26_Iss__c,QTB_S26_Type__c,QTB_S26_Sub__c,
                                       QTB_S26_Private_Key__c,QTB_S26_Kid__c,QTB_S26_JWTToken__c From QTB_S26_RS256_JWT__mdt Where DeveloperName=: Label.QTB_S26_JWTAlgorithm];
			//Statci Token this will exipire on 30 SEP 12:00 AM GMT
			//JWT Token is stored in custom metadata
            String JWTToken = rs.QTB_S26_JWTToken__c;
            JWTHeader head = new JWTHeader();
            head.alg = rs.QTB_S26_Alg__c;
            head.type = rs.QTB_S26_Type__c;
            head.kid= rs.QTB_S26_Kid__c;
            String headerJson = JSON.serialize(head);
            String header_encoded = EncodingUtil.base64Encode(blob.valueof(headerJson)); 
            system.debug('header_encoded:'+header_encoded);
            
            JWTBody body = new JWTBody();
            body.iss=rs.QTB_S26_Iss__c;
            body.sub=rs.QTB_S26_Sub__c;
            body.aud=rs.QTB_S26_Aud__c;
            body.iat = Integer.valueof(datetime.now().getTime()/1000);
            body.exp = Integer.valueof((datetime.now().getTime()/1000) + 32400);
            String bodyJson = JSON.serialize(body);	
            
            String body_encoded = EncodingUtil.base64Encode(blob.valueOf(bodyJson)); 
            String signature_encoded = header_encoded + '.' + body_encoded;
            String signature_encoded_url = EncodingUtil.urlEncode(signature_encoded,'UTF-8');
            blob signature_blob = blob.valueof(signature_encoded_url);
            system.debug('signature_blob:'+signature_blob);
            
            Blob private_key = EncodingUtil.base64Decode(rs.QTB_S26_Private_Key__c);
            String signature_blob_string = EncodingUtil.base64Encode(Crypto.sign('RSA-SHA256', signature_blob, private_key));
            
            String JWT = signature_encoded + '.' + signature_blob_string; 
            system.debug('JWT:'+JWT);
            JWT = JWT.replace('+', '-').replace('/', '_').replace('=','');
            System.debug('JWT:'+JWT);
            return JWTToken;		  
        } catch(Exception e){
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                QTBS26JWT
            );
            throw e;
        }
    }
}