function initialize(application, {entry_node_selector, flags}){
    application.init({
        node: document.querySelector(entry_node_selector),
        flags: flags
    })
    return application
}

const config = {
    entry_node_selector : "#app",
    flags : {
        joke_api : {
            base_url : "https://api.chucknorris.io",
            api_key : ""
        },
        gif_api : {
            base_url : "https://g.tenor.com/v1",
            api_key : "UU4YTAMREHDI"
        },
        gif_set_max_length : 20
    }
}

const app = initialize(Elm.Main, config)