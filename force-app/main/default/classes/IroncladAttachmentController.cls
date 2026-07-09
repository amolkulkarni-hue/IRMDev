public class IroncladAttachmentController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOpportunityFiles(String opportunityId) {
        List<Map<String, String>> fileList = new List<Map<String, String>>();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :opportunityId
        ];

        for (ContentDocumentLink link : links) {
            Map<String, String> fileMap = new Map<String, String>();
            fileMap.put('id', link.ContentDocument.LatestPublishedVersionId);
            fileMap.put('name', link.ContentDocument.Title);
            fileList.add(fileMap);
        }

        return fileList;
    }

    // Concatenates two Blobs into one, byte-array safe
    private static Blob concatenateBlobs(Blob first, Blob second) {
        String firstHex = EncodingUtil.convertToHex(first);
        String secondHex = EncodingUtil.convertToHex(second);
        return EncodingUtil.convertFromHex(firstHex + secondHex);
    }

    @AuraEnabled
    public static String uploadAttachments(
        String workflowId,
        String attributeId,
        List<Id> contentVersionIds
    ) {
        List<String> errors = new List<String>();

        for (Id cvId : contentVersionIds) {
            ContentVersion cv = [
                SELECT VersionData, Title, FileExtension
                FROM ContentVersion
                WHERE Id = :cvId
                LIMIT 1
            ];

            String boundary = '----IroncladBoundary' + String.valueOf(Crypto.getRandomLong());
            String filename = cv.Title + '.' + cv.FileExtension;

            String header = '--' + boundary + '\r\n'
                + 'Content-Disposition: form-data; name="attachment"; filename="' + filename + '"\r\n'
                + 'Content-Type: application/octet-stream\r\n\r\n';

            String footer = '\r\n--' + boundary + '\r\n'
                + 'Content-Disposition: form-data; name="metadata"\r\n\r\n'
                + '{"comment": {"message": "Uploaded from Salesforce"}}\r\n'
                + '--' + boundary + '--';

            Blob headerBlob = Blob.valueOf(header);
            Blob fileBlob = cv.VersionData;
            Blob footerBlob = Blob.valueOf(footer);

            Blob bodyBlob = concatenateBlobs(concatenateBlobs(headerBlob, fileBlob), footerBlob);

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Ironclad_NC/public/api/v1/workflows/'
                + workflowId + '/documents/' + attributeId);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
            req.setHeader('x-as-user-email', UserInfo.getUserEmail());
            req.setBodyAsBlob(bodyBlob);
            req.setTimeout(60000);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() != 200 && res.getStatusCode() != 204) {
                String responseBody = res.getBody();
					if (responseBody.contains('Cannot upload multiple files with the same name')) {
    					errors.add(filename + ' — File already exists in this workflow.');
					} else if (res.getStatusCode() == 409 || responseBody.contains('INVALID_STATE')) {
					    errors.add(filename + ' — Files can only be uploaded when the workflow is in Review stage.');
					} else {
					    errors.add('Failed: ' + filename + ' — ' + res.getStatusCode() + ' - ' + responseBody);
					}
            }
        }

        return errors.isEmpty() ? 'Success' : String.join(errors, '; ');
    }
}