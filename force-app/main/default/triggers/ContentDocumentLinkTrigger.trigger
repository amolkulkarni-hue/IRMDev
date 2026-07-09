trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    // Make all new file links visible to Community Users.
    // Skip owner/inferred links (ShareType = 'I') — Salesforce does not allow
    // changing Visibility on those and throws "Override Touch Level" if you try.
    for (ContentDocumentLink l : Trigger.new) {
        if (l.ShareType != 'I') {
            l.Visibility = 'AllUsers';
        }
    }
}