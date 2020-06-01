const axios = require('axios');

const workplaceAPI = axios.create({

    method: 'POST',

    baseURL: 'https://graph.facebook.com/v3.3/me/messages',

    headers: {

        Authorization: 'Bearer DQVJ1V3dyUE5hQ09zd05DWHo1cWNGVHpzUUR6QmlCYzNjZAEZACMWRPc0xBVExBSnYzSy0tWGQtZAjNfc0JGQ2QydER2VmdQbzJBcG9mUG4yZAHdTOEtPU2lCb01VQUpSNURBdlVOTHc4SlhSX3NJN0dhazJiRkowUjMxLS1mUndrZAWhRbUJvYmNwcFhhOFJLOWthOUJWYnkxLWNCSjFnRzB4ZAFVFWjc1aGd0dHgtZAFE5OFQ4bDJRc09xUWc0Qmo4YjQ1d1MzakNLWGh6cnJ4NWtZAVwZDZD'
    }

});

workplaceAPI({

    data: {

        recipient: {

            id: '100039033136879'

        },

        message: {

            text: 'hello, Support Bot! From NodeJS'

        }

    }
})


// const axios = require('axios');
//
// const workplaceAPI = axios.create({
//
//     method: 'POST',
//
//     baseURL: 'https://graph.facebook.com/me/messages',
//
//     headers: {
//
//         Authorization: 'Bearer DQVJ1V3dyUE5hQ09zd05DWHo1cWNGVHpzUUR6QmlCYzNjZAEZACMWRPc0xBVExBSnYzSy0tWGQtZAjNfc0JGQ2QydER2VmdQbzJBcG9mUG4yZAHdTOEtPU2lCb01VQUpSNURBdlVOTHc4SlhSX3NJN0dhazJiRkowUjMxLS1mUndrZAWhRbUJvYmNwcFhhOFJLOWthOUJWYnkxLWNCSjFnRzB4ZAFVFWjc1aGd0dHgtZAFE5OFQ4bDJRc09xUWc0Qmo4YjQ1d1MzakNLWGh6cnJ4NWtZAVwZDZD'
//
//     }
//
// });
//
// const sendMessage = (id, message) => {
//
//     workplaceAPI({
//
//         data: {
//
//             recipient: {
//
//                 id: id
//
//             },
//
//             message: {
//
//                 text: message
//
//             }
//
//         }
//
//     })
//
// }
//
// sendMessage('100039033136879', 'hello, world! From NodeJS refactored')