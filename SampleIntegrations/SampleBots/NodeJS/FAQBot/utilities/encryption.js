module.exports = function(crypto, config){

  let module = {};

  //Signature checking function
  module._signCheck = function (req, res, buf) {
    let signature = req.headers['x-hub-signature'];
    if (!signature) throw new Error('Couldn\'t validate the request signature.');
    else {
      let elements = signature.split('=');
      let signatureHash = elements[1];
      let expectedHash = crypto.createHmac('sha1', config.APP_SECRET)
		     .update(buf)
		     .digest('hex');
      if (signatureHash != expectedHash) throw new Error('Couldn\'t validate the request signature.');
    }
  }

  return module;

}
