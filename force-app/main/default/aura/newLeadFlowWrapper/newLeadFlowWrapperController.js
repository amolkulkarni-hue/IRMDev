({
    handleFlowFinished : function(component, event, helper) {
        component.set("v.showComponent", false);

        var recordId = event.getParam("recordId");
        console.log('Flow finished with recordId: ' + recordId);
        if (recordId) {
            window.location.href = '/lightning/r/Lead/' + recordId + '/view';
        } else {
            window.location.href = '/lightning/o/Lead/list?filterName=Recent';
        }
    }
})