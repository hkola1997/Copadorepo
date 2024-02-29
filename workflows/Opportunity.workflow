<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Test_Email_notofication_Testing_for_account_name_change</fullName>
        <description>Test-Email notofication Testing for account name change</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/test_Account_Name_changed_Notification_1681104218751</template>
    </alerts>
    <fieldUpdates>
        <fullName>Status_field_of_Opportunity</fullName>
        <field>Description</field>
        <formula>&quot; chandu validation rule High Value&quot;</formula>
        <name>Status field of Opportunity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Closed won test workflow</fullName>
        <actions>
            <name>send_them_welcome_letter</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Closed Won</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>update status of oppurtunity if 10000</fullName>
        <actions>
            <name>Status_field_of_Opportunity</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Amount</field>
            <operation>greaterThan</operation>
            <value>10000</value>
        </criteriaItems>
        <description>create a workflow rule that automatically updates the status of an opportunity when its amount exceeds $10,000.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>send_them_welcome_letter</fullName>
        <assignedToType>owner</assignedToType>
        <dueDateOffset>2</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Opportunity.CloseDate</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>send them welcome letter</subject>
    </tasks>
</Workflow>