/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Controller
 * @description For List View display of archived Case emails
 */

public class ArchivedEmailListViewController {
    public final Id parentCaseId{get; set;}
    @TestVisible private Integer pageNumber = 0;
    private List<List<Archive_Email__b>> archiveEmailPagination;
    private Integer pageSize = 5;

    public ArchivedEmailListViewController(ApexPages.StandardController stdCont) {
        this.parentCaseId = Apexpages.currentPage().getParameters().get('caseId');
        this.pageSize = (String.isBlank(Apexpages.currentPage().getParameters().get('displaySize')))? 
          5 : Integer.valueOf(Apexpages.currentPage().getParameters().get('displaySize'));

        if(this.parentCaseId == null) {
          this.parentCaseId = stdCont.getRecord().Id;
        }
        queryArchivedEmail();
    }

    private void queryArchivedEmail() {
      this.archiveEmailPagination = new List<List<Archive_Email__b>>();
        Integer counter = 0;
        List<Archive_Email__b> currentPage;
        for(Archive_Email__b email : [SELECT Case__c,
                                       Email__c,
                                       Status__c,
                                       Subject__c,
                                       MessageDate__c,
                                       ToAddress__c
                                    FROM Archive_Email__b
                                    WHERE Case__c =: this.parentCaseId]) {
            if(counter == this.pageSize) {
                counter = 0;
            }
            if(counter == 0) {
                this.archiveEmailPagination.add(new List<Archive_Email__b>());
                currentPage = this.archiveEmailPagination.get(archiveEmailPagination.size()-1);
            }
            currentPage.add(email);
            counter++;
        }
    }

    public List<Archive_Email__b> getArchivedEmails() {
        if (this.archiveEmailPagination.isEmpty()) return null;
        return this.archiveEmailPagination.get(this.pageNumber);
    }
    
    public void Previous() {
        this.pageNumber--;
    }
    
    public void Next() {
        this.pageNumber++;
    }
    
    public Boolean getDisablePrevious() {
        return pageNumber == 0;
    }
    
    public Boolean getDisableNext() {
        return pageNumber >= this.archiveEmailPagination.size()-1;
    }

   public Integer getPageSize() {
      return this.pageSize;
   }
   public Boolean getDisplayFullListButton() {
        return (this.archiveEmailPagination != null && this.archiveEmailPagination.size() > 1);
   }
}