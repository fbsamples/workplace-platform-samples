const baseURI = 'https://graph.work.meta.com/'
const appID = '<replace-with-app-id>'
const appSecret = '<replace-with-app-secret>'
const appAccessToken = `${appID}|${appSecret}`

const aResoldCommunityId = COMMUNITY_ID
const testResellerId = RESELLER_ID
const testCustomerAddressId = ADDRESS_ID
const testDeviceBoxSerial = 'Serial123';
const testPoNumber = 'PO123';
const testOrderId = 'order_id_1';

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

async function inviteNewResoldGenesisAdminToQ4B(resellerId, adminEmail, countryCode, is_govt_affiliated) {
    const body = {
        poc_email: adminEmail,
        reseller_id: resellerId,
        work_product_type: 'QUEST_FOR_BUSINESS',
        country: countryCode,
        is_govt_affiliated: is_govt_affiliated
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

async function linkWithResellerUsingResellerCode(resellerId, resellerCode, countryCode, is_govt_affiliated) {
    const body = {
        reseller_code: resellerCode,
        reseller_id: resellerId,
        country: countryCode,
        is_govt_affiliated: is_govt_affiliated
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


async function addCustomerAddress(name, address, city, country_code, email) {
    const body = {
        name: name,
        address: address,
        city: city,
        country_code: country_code,
        email: email,
    };
    responseData =
        await makeWorkApiRequestUsingAppAccessToken('work_platform_customer_address', 'POST', body);
    console.log(responseData);
    return responseData.customer_address_id;
}

async function registerOrder(resellerId, partner_order_id, order_date, customer_address_id, poNumber, device_box_serial) {
    const body = {
        reseller_id: resellerId,
        partner_order_id: partner_order_id,
        sale_date: order_date,
        customer_address_id: customer_address_id,
        po_number: poNumber,
        device_count: 1,
        devices: [{
            box_serial_number: device_box_serial,
            sku: '301-00178-01',
            warranty_type: 'LIMITED_WARRANTY'
        }]
    }
    responseData = await makeWorkApiRequestUsingAppAccessToken('work_platform_order', 'POST', body);
    console.log(responseData);
    return responseData.success;
}


async function enrollHeadset(resellerId, communityId, distributor_order_id, serialNumber) {
    const body = {
        reseller_id: resellerId,
        community_id: communityId,
        distributor_order_id: distributor_order_id,
        device: { serial_number: serialNumber }
    }
    responseData = await makeWorkApiRequestUsingAppAccessToken('work_platform_enroll_device', 'POST', body);
    console.log(responseData);
    return responseData.success;
}

async function cancelHeadsetEnrolment(serialNumber) {
    const body = {
        device: { serial_number: serialNumber }
    }
    responseData = await makeWorkApiRequestUsingAppAccessToken('work_platform_cancel_enroll_device', 'POST', body);
    console.log(responseData);
    return responseData.success;
}



async function runExamples() {
    // const resellerId = await registerNewReseller(
    //     'New reseller co.',
    //     'John Reseller',
    //     'john@reseller.com',
    //     '+18007854521',
    //     'us',
    //     'Austin',
    //     'Independence Way'
    // );
    // await getResellerInfo(resellerId);
    // invitationId =
    //    await inviteNewResoldGenesisAdminToQ4B(1310217616558427, 'q4badmin@resold.thomasr.co.uk','US',false);
    // await getInvitationInfo(invitationId);
    // This will only work if a new reseller code is generated
    // communityId = await linkWithResellerUsingResellerCode(1310217616558427, '2zIpksSALqs7O3JK|942530923502196', 'US', false)
    // await cancelQ4B(1310217616558427, 686095996027324);
    // await cancelSell(686095996027324);


    // addressID = await addCustomerAddress('John Doe', '1 Hacker Way', 'Menlo Park', 'US', 'johndoe@gmail.com');
    // todayDateString = new Date().toISOString().substring(0, 10);
    // distributor_order_id = await registerOrder(testResellerId, testOrderId, todayDateString, testCustomerAddressId, testPoNumber, 1, testDeviceBoxSerial)
    // await enrollHeadset(testResellerId, thomasResoldCommunityId, testOrderId, testDeviceBoxSerial);
    // await cancelHeadsetEnrolment(testDeviceBoxSerial);

    runExamples()
