import Player from "./player"

let Video = {
  init(socket, element) {
    let playerId = element.getAttribute("data-player-id")
    let videoId = element.getAttribute("data-id")

    socket.connect();

    Player.init(element.id, playerId, () => {
      this.onReady(videoId, socket)
    })
  },

  onReady(videoId, socket) {
    let msgContainer = document.getElementById("msg-container")
    let msgInput = document.getElementById("msg-input")
    let postButton = document.getElementById("msg-submit")
    let videoChannel = socket.channel("videos:"+videoId)

    postButton.addEventListener("click", e => {
      let payload = {body: msgInput.value, at: Player.getCurrentTime()};
      videoChannel.push("new_annotation", payload)
        .receive("error", e => console.log(e))
      msgInput.value = ""
    })

    videoChannel.on("new_annotation", (resp) => {
      videoChannel.params.last_seen_id = resp.id
      this.scheduleMessages(msgContainer, [resp])
    })

    msgContainer.addEventListener("click", e => {
      e.preventDefault()
      let seconds = e.target.getAttribute("data-seek") || e.target.parentNode.getAttribute("data-seek")
      if(!seconds) return

      Player.seekTo(seconds)
    })

    videoChannel.join()
      .receive("ok", (resp) => {
        let ids = resp.annotations.map(annotation => annotation.id)
        videoChannel.params.last_seen_id = Math.max(...ids)
        this.scheduleMessages(msgContainer, resp.annotations)
      })
      .receive("error", reason => console.log("join failed", reason))
  },

  esc(str){
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  scheduleMessages(msgContainer, annotations) {
    setTimeout(() => {
      let currentTime = Player.getCurrentTime()
      let remaining = this.renderAtTime(annotations, currentTime, msgContainer)

      this.scheduleMessages(msgContainer, remaining)
    }, 1000)
  },

  renderAtTime(annotations, seconds, msgContainer) {
    return annotations.filter(annotation => {
      if(annotation.at > seconds) {
        return true;
      } else {
        this.renderAnnotation(msgContainer, annotation)
        return false;
      }
    });
  },

  formatTime(at) {
    let date = new Date(null);
    date.setSeconds(at / 1000)
    return date.toISOString().substr(14, 5);
  },

  renderAnnotation(msgContainer, {user, body, at}) {
/*    console.log("renderAnnotation:", body, at)*/
    let template = document.createElement("div");
    template.innerHTML = `
    <a href="#" data-seek="${this.esc(at)}">
    <span class="time">[${this.formatTime(at)}]</span>
    <b>${this.esc(user.username)}</b>: ${this.esc(body)}
    </a>
    `

    let annotationList = msgContainer.children
/*    console.log("annotationList",annotationList)*/
    var ix = annotationList.length
/*    console.log('ix: ', ix);*/
    var annotationContainer
    while(--ix >= 0) {
/*      console.log("checking "+ix)*/
      annotationContainer = annotationList[ix]
      let childAt = parseInt(annotationContainer.firstElementChild.getAttribute("data-seek"))
      if(childAt < at) {
        break;
      }
    }
    if(annotationContainer) {
      annotationContainer = annotationContainer.nextSibling
    }

    msgContainer.insertBefore(template, annotationContainer)
    msgContainer.scrollTop = msgContainer.scrollHeight
  }
}

export default Video