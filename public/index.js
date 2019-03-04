import { Elm } from "../src/Main.elm";

const KINTO_URL = "https://kinto-dev.classea12.beta.gouv.fr/v1/";
const loginForm = window.localStorage.getItem("session");
const app = Elm.Main.init({
    flags: {
        loginForm: loginForm,
        version: "%VERSION%",
        kintoURL: KINTO_URL,
        navigatorShare: navigator.share !== undefined,
        staticFiles: {
            "logo": require("./logo.png"),
            "logo_ca12": require("./logo_ca12.png"),
            "autorisationCaptationImageMineur": require("./documents/Autorisation-captation-image-mineur_2017.pdf"),
            "autorisationCaptationImageMajeur": require("./documents/Autorisation-captation-image-majeur_2017.pdf")
        }
    }
});

// A video was selected in the file input, return its object URL so it can be set as a `src` attribute on a video element
app.ports.videoSelected.subscribe(function (nodeID) {
    const fileInput = document.getElementById(nodeID);
    if (fileInput === null) {
        console.error("Didn't find a file input with id", nodeID);
        return;
    }
    const file = fileInput.files[0];
    const videoObjectUrl = URL.createObjectURL(file);
    app.ports.videoObjectUrl.send(videoObjectUrl);

    // Preview the thumbnail for the selected video.
    const videoNode = document.getElementById("uploaded-video");
    videoNode.src = videoObjectUrl;
    videoNode.parentNode.style.display = "block";
    videoNode.addEventListener("canplay", function () {
        // The video is "available", let's preview the thumbnail.
        const ratio = videoNode.videoHeight / videoNode.videoWidth;
        const canvas = document.getElementById("thumbnail-preview");
        canvas.height = Math.min(videoNode.videoHeight, 300);
        canvas.width = canvas.height / ratio; // respect the video ratio
        updatePreview(canvas, videoNode, ratio);
        videoNode.addEventListener("timeupdate", function () {
            // The video cursor has been moved, update the thumbnail preview.
            updatePreview(canvas, videoNode, ratio);
        }, true);
    }, true);
});

function updatePreview(canvasNode, videoNode, ratio) {
    canvasNode.getContext("2d").drawImage(videoNode, 0, 0, 300 / ratio, 300);
};

function uuidv4() {
    function getRandValue(c) {
        return (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    }
    return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, getRandValue)
}

function dataURItoBlob(dataURI) {
    // convert base64 data component to raw binary data held in a string
    // A data URI looks like that: "data:image/jpeg;base64,<base64 encoded data>"
    splitted = dataURI.split(",");
    const mimetype = splitted[0].replace("data:", "").replace(";base64", "");
    const data = splitted[1];
    const byteString = atob(data);

    // write the bytes of the string to a typed array
    var ia = new Uint8Array(byteString.length);
    for (var i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i);
    }

    return new Blob([ia], { type: mimetype });
}

const collectionToMessage = {
    "thumbnails": "Envoi de la miniature",
    "upcoming": "Envoi de la vidéo",
    "comments": "Envoi de la pièce jointe",
}

function xhrForAttachment(collection, recordID, credentials, errorCallback) {
    // Yes, it would be way nicer to be able to use the GlobalFetch API. But we wouldn't have any report on the progress. :sadface:
    let xhr = new XMLHttpRequest();
    xhr.open("POST", KINTO_URL + "buckets/classea12/collections/" + collection + "/records/" + recordID + "/attachment");
    xhr.upload.addEventListener("progress", function (event) {
        if (event.lengthComputable) {
            const percentage = Math.round(event.loaded * 100 / event.total);
            const message = collectionToMessage[collection];
            app.ports.progressUpdate.send({ "percentage": percentage, "message": message });
        }
    }, false);
    xhr.onerror = function (event) {
        console.error("network error", event.target);
        errorCallback(this.response);
    }
    xhr.setRequestHeader("Authorization", "Basic " + credentials);
    return xhr;
}

// A new video record has been created, upload the selected video file as an attachment
app.ports.submitVideo.subscribe(function (data) {
    const nodeID = data.nodeID;
    const videoNodeID = data.videoNodeID;
    const videoData = data.videoData;
    const login = data.login;
    const password = data.password;
    const credentials = btoa(login + ":" + password);
    const fileInput = document.getElementById(nodeID);
    if (fileInput === null) {
        console.error("Didn't find a file input with id", nodeID);
        return;
    }
    const videoNode = document.getElementById(videoNodeID);
    if (videoNode === null) {
        console.error("Didn't find a video node with id", videoNodeID);
        return;
    }

    // Get the duration from the video.
    videoData.duration = parseInt(videoNode.duration, 10);

    // Create a thumbnail from the video.
    const canvas = document.getElementById("thumbnail-preview");
    const thumbnail = dataURItoBlob(canvas.toDataURL("image/png"));

    // Upload the thumbnail as an attachment
    const recordID = uuidv4();
    const filename = recordID + ".png";
    let thumbnailData = new FormData();
    thumbnailData.append('attachment', thumbnail, filename);
    thumbnailData.append('data', JSON.stringify({ "for": recordID }));

    let xhrThumbnail = xhrForAttachment("thumbnails", uuidv4(), credentials, app.ports.videoSubmitted.send);
    xhrThumbnail.onload = function () {
        // The thumbnail was uploaded, now upload the video.
        const response = JSON.parse(this.response);
        if (!response.location) {
            console.error("Error while uploading the thumbnail", response);
            app.ports.videoSubmitted.send(this.response);
            return;
        }
        videoData.thumbnail = response.location;

        const file = fileInput.files[0];
        // Create a multipart form to upload the file.
        let formData = new FormData();
        formData.append('attachment', file);
        formData.append('data', JSON.stringify(videoData));

        let xhrVideo = xhrForAttachment("upcoming", recordID, credentials, app.ports.videoSubmitted.send);
        xhrVideo.onload = function () {
            app.ports.videoSubmitted.send(this.response);
        }
        xhrVideo.send(formData);
        videoNode.parentNode.style.display = "none";
    }
    xhrThumbnail.send(thumbnailData);

});

// A new comment record has been created, upload the selected file as an attachment
app.ports.submitAttachment.subscribe(function ({ nodeID, commentID, login, password }) {
    const credentials = btoa(`${login}:${password}`);
    const fileInput = document.getElementById(nodeID);
    if (fileInput === null) {
        console.error("Didn't find a file input with id", nodeID);
        return;
    }

    const file = fileInput.files[0];
    // Create a multipart form to upload the file.
    let formData = new FormData();
    formData.append('attachment', file);

    let xhrAttachment = xhrForAttachment("comments", commentID, credentials, app.ports.attachmentSubmitted.send);
    xhrAttachment.onload = function () {
        app.ports.attachmentSubmitted.send(this.response);
    }
    xhrAttachment.send(formData);
});

// Event polyfill for IE.
(function () {
    if (typeof window.CustomEvent === "function") return false; //If not IE

    function CustomEvent(event, params) {
        params = params || { bubbles: false, cancelable: false, detail: undefined };
        var evt = document.createEvent('CustomEvent');
        evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
        return evt;
    }

    CustomEvent.prototype = window.Event.prototype;

    window.Event = CustomEvent;
})();

// A new url has been loaded using pushstate, we need to tell matomo/piwik (analytics) by firing an event
app.ports.newURL.subscribe(function (url) {
    window.dispatchEvent(new Event('newURL'));
});

app.ports.saveSession.subscribe(function (sessionData) {
    localStorage.setItem("session", JSON.stringify(sessionData));
});

app.ports.logoutSession.subscribe(function () {
    localStorage.removeItem("session");
});

app.ports.navigatorShare.subscribe(function (shareText) {
    if (navigator.share !== undefined) {
        navigator.share({ url: document.location.href, text: shareText });
    }
});