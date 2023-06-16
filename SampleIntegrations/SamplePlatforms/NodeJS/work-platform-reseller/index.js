const baseURI = 'https://graph.work.meta.com/'
const appID = '<replace-with-app-id>'
const appSecret = '<replace-with-app-secret>'
const appAccessToken = `${appID}|${appSecret}`

async function makeWorkApiRequestUsingAppAccessToken(path, method = 'GET', body = null) {
    const response = await fetch(`${baseURI}${path}?access_token=${appAccessToken}`, {
        method: method,
        body: body == null ? null : JSON.stringify(body),
        headers: {
            'Content-Type': 'application/json',
        },
    });
    return response.json();
}

async function registerNewReseller(entityName, pocName, pocEmail, pocPhoneNumber, country, city, address) {
    const body = {
        entity_name: entityName,
        poc_name: pocName,
        poc_email: pocEmail,
        poc_phone_number: pocPhoneNumber,
        country: country,
        city: city,
        address: address,
        approved_data_sharing: true
    }
    responseData =
        await makeWorkApiRequestUsingAppAccessToken('work_platform_reseller', 'POST', body)
    console.log(responseData)
    return responseData.id
};

async function getResellerInfo(resellerId) {
    responseData = makeWorkApiRequestUsingAppAccessToken(resellerId)
    console.log(await responseData)
};

async function inviteNewResoldGenesisAdminToQ4B(resellerId, adminEmail) {
    const body = {
        poc_email: adminEmail,
        reseller_id: resellerId,
        work_product_type: 'QUEST_FOR_BUSINESS',
    }
    responseData =
        await makeWorkApiRequestUsingAppAccessToken('work_platform_send_company_creation_invite', 'POST', body)
    console.log(responseData)
    return responseData.id
};

async function getInvitationInfo(invitationId) {
    responseData = makeWorkApiRequestUsingAppAccessToken(invitationId)
    console.log(await responseData)
};

async function linkWithResellerUsingResellerCode(resellerId, resellerCode) {
    const body = {
        reseller_code: resellerCode,
        reseller_id: resellerId,
    }
    responseData =
        await makeWorkApiRequestUsingAppAccessToken('work_platform_sell_instance', 'POST', body)
    console.log(responseData)
    return responseData.community_id
};

async function cancelQ4B(resellerId, communityId) {
    const body = {
        community_id: communityId,
        reseller_id: resellerId,
        products: [{ product_name: 'QUEST_FOR_BUSINESS' }]
    }
    responseData =
        await makeWorkApiRequestUsingAppAccessToken('work_platform_cancel_products', 'POST', body)
    console.log(responseData)
    return responseData.community_id
};

async function cancelSell(communityId) {
    const body = {
        community_id: communityId,
    }
    responseData =
        await makeWorkApiRequestUsingAppAccessToken('work_platform_cancel_instance_sell', 'POST', body)
    console.log(responseData)
    return responseData.community_id
};

async function runExamples() {
    const resellerId = await registerNewReseller(
        'New reseller co.',
        'John Reseller',
        'john@reseller.com',
        '+18007854521',
        'us',
        'Austin',
        'Independence Way'
    );
    await getResellerInfo(resellerId);
    invitationId =
        await inviteNewResoldGenesisAdminToQ4B(1310217616558427, 'q4badmin@resold.thomasr.co.uk');
    await getInvitationInfo(invitationId);
    //This will only work if a new reseller code is generated
    // communityId = await linkWithResellerUsingResellerCode(1310217616558427, '1YU74AOckqk8BlQH|2262203450616545') 
    await cancelQ4B(1310217616558427, 686095996027324);
    await cancelSell(686095996027324);
}

runExamples()