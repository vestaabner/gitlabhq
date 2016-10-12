((global) => {

  class GLTerminal {

    constructor(options) {
      this.options = options || {};

      options.cursorBlink = options.cursorBlink || true;
      options.screenKeys  = options.screenKeys || true;
      options.cols = options.cols || 100;
      options.rows = options.rows || 40;
      this.container = document.querySelector(options.selector);

      this.setSocketUrl();
      this.createTerminal();
    }

    setSocketUrl() {
      const {protocol, hostname, port} = window.location;
      const wsProtocol = protocol === 'https:' ? 'wss://' : 'ws://';
      const path = this.container.dataset.projectPath;

      this.socketUrl = `${wsProtocol}${hostname}:${port}${path}`
    }

    createTerminal() {
      this.terminal = new Terminal(this.options);
      this.socket = new WebSocket(this.socketUrl);

      this.terminal.open(this.container);
      this.terminal.fit();

      this.socket.onopen = () => { this.runTerminal() };
      this.socket.onclose = () => { this.handleSocketFailure() };
      this.socket.onerror = () => { this.handleSocketFailure() };
    }

    runTerminal() {
      const {cols, rows} = this.terminal.proposeGeometry();
      const {offsetWidth, offsetHeight} = this.terminal.element;

      this.charWidth = Math.ceil(offsetWidth / cols);
      this.charHeight = Math.ceil(offsetHeight / rows);

      this.terminal.attach(this.socket);
      this.isTerminalInitialized = true;
      this.setTerminalSize(cols, rows);
    }

    setTerminalSize (cols, rows) {
      const width = `${(cols * this.charWidth).toString()}px`;
      const height = `${(rows * this.charHeight).toString()}px`;

      this.container.style.width = width;
      this.container.style.height = height;
      this.terminal.resize(cols, rows);
    }

    handleSocketFailure() {
      console.error('There is a problem with Terminal connection. Please try again!');
    }

  }

  global.Terminal = GLTerminal;

})(window.gl || (window.gl = {}))
