public with sharing class DocuSignPDFService {

    @future(callout=true)
    public static void downloadAndStorePDF(String envelopeId, Id parentId) {
        try {
            String namedCredential = 'DocuSignNC';
            String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/DocuSignPDFService';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + namedCredential + '/restapi/v2.1/accounts/a3451c81-ddf7-4976-b230-22c246e126cc/envelopes/' + envelopeId + '/documents/1');
            req.setMethod('GET');
            req.setHeader('Accept', 'application/pdf');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Blob pdfBlob = res.getBodyAsBlob();
                ContentVersion cv = new ContentVersion();
                cv.Title = 'DocuSign_Envelope_' + envelopeId;
                cv.PathOnClient = 'DocuSign_Envelope_' + envelopeId + '.pdf';
                cv.VersionData = pdfBlob;
                insert cv;

                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
                cdl.LinkedEntityId = parentId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;

                System.debug('PDF saved for envelope ' + envelopeId + ' linked to record ' + parentId);
            } else {
                System.debug('Failed to download PDF for envelope ' + envelopeId + '. Status: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error in downloadAndStorePDF: ' + e.getMessage());
        }
    }
}