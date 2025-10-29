class MapsBlack extends HTMLElement {
  static observedAttributes = ["zoom", "lat", "lon", "pitch", "bearing", "loading", "navigationcontrol", "markers", "languages", "languagemode", "changemode", "mapstyle", "mapstyleurl", "mapstylejson", "loader", "preloadmargin", "terrain", "hillshade", "contours", "globe", "attribution", "cooperativegestures", "baseurl", "inspect"]

  constructor() {
    super()
    this.attachShadow({ mode: 'open' })
    this.mapid = this.randomId()
    const componentStyles = new CSSStyleSheet()
    componentStyles.replaceSync(`:host{display:block;position:relative;min-height:500px;color:rgba(0,0,0,.75);}:host([hidden]){display:none}.maplibregl-map{position:absolute;top:0;right:0;bottom:0;left:0;}.maplibregl-ctrl-attrib.maplibregl-ctrl-attrib{padding: 2px 24px 2px 0px;}.maplibregl-ctrl-attrib.maplibregl-ctrl-attrib[open]{padding: 2px 28px 2px 8px;visibility: visible;}.maplibregl-ctrl-attrib.maplibregl-ctrl-attrib[open] .maplibregl-ctrl-attrib-inner{display: block;}.maplibregl-ctrl-attrib.maplibregl-ctrl-attrib .maplibregl-ctrl-attrib-inner{display: none;}.attributionPopup{font-family:Helvetica Neue,Arial,Helvetica,sans-serif;display:none;position: absolute;top: 0;right: 0;bottom: 0;left: 0;background: rgba(255, 255, 255, 0.8);padding: 1rem;margin: 0.5rem;z-index: 100;box-shadow: 0 0 0 2px rgba(0, 0, 0, .1);border-radius: 4px;flex-direction:column;}.attributionCloseLink{text-decoration: none;}.attributions{max-height:100%;overflow:auto;}`)
    this.shadowRoot.adoptedStyleSheets.push(componentStyles)
  }

  connectedCallback() {
    if (this.loading === 'eager') {
      this.loadMap()
      return
    }
    let observer = new IntersectionObserver(
      entries => entries.forEach((entry) => {
        if (entry.isIntersecting) {
          observer.disconnect()
          this.loadMap()
        }
      }),
      { rootMargin: `${this.preloadmargin} ${this.preloadmargin} ${this.preloadmargin} ${this.preloadmargin}` }
    )
    observer.observe(this)
  }

  disconnectedCallback() {
    if (this.map) this.map.remove()
  }

  reinitMapAttributes = ["baseurl", "cooperativegestures", "attribution", "contours", "globe", "hillshade", "terrain", "loader", "mapstylejson", "mapstyleurl", "mapstyle", "languagemode", "languages", "markers", "navigationcontrol", "inspect"]

  cameraAttributes = ['lon', 'lat', 'bearing', 'zoom', 'pitch']

  attributeChangedCallback(name, oldValue, newValue) {
    if (!this.map) {
      return
    }

    // When we set from maplibre as a source we set ignoreCameraChanges to prevent a feedback loop
    if (this.cameraAttributes.includes(name) && !this.ignoreCameraChanges) {
      this.map[this.changemode === 'flyto' ? 'flyTo' : 'jumpTo']({
        center: [this.lon, this.lat],
        zoom: this.zoom,
        pitch: this.pitch,
        bearing: this.bearing
      })
    } else if (this.reinitMapAttributes.includes(name)) {
      this.reinitMap()
    }
  }

  randomId() {
    return Math.random().toString(36).substring(2, 12)
  }

  loadMap() {
    const mapcontainer = document.createElement('div')
    this.shadowRoot.appendChild(mapcontainer)
    const mainScript = new URL('./maps.black.js', this.baseurl)
    import(mainScript).then(maplib => maplib.default(mapcontainer, this))
  }

  reinitMap() {
    if (this.map && !this.map._removed) {
      this.map.remove()
      this.mapid = this.randomId()
      this.licenses = false
      this.requireAttribution = false
      this.loadMap()
    }
  }

  set zoom(value) {
    this.setAttribute('zoom', value)
  }

  get zoom() {
    return parseFloat(this.getAttribute('zoom') || 0)
  }

  set lat(value) {
    this.setAttribute('lat', value)
  }

  get lat() {
    return parseFloat(this.getAttribute('lat') || 0)
  }

  set lon(value) {
    this.setAttribute('lon', value)
  }

  get lon() {
    return parseFloat(this.getAttribute('lon') || 0)
  }

  set pitch(value) {
    this.setAttribute('pitch', value)
  }

  get pitch() {
    return parseFloat(this.getAttribute('pitch') || 0)
  }

  set bearing(value) {
    this.setAttribute('bearing', value)
  }

  get bearing() {
    return parseFloat(this.getAttribute('bearing') || 0)
  }

  set loading(value) {
    this.setAttribute('loading', value)
  }

  get loading() {
    return this.getAttribute('loading') || 'lazy'
  }

  set preloadmargin(value) {
    this.setAttribute('preloadmargin', value)
  }

  get preloadmargin() {
    return this.getAttribute('preloadmargin') || '200px'
  }

  set navigationcontrol(value) {
    this.setAttribute('navigationcontrol', value)
  }

  get navigationcontrol() {
    return JSON.parse(this.getAttribute('navigationcontrol') || 'false')
  }

  set markers(value) {
    this.setAttribute('markers', value)
  }

  get markers() {
    return this.getAttribute('markers') ? JSON.parse(this.getAttribute('markers')) : []
  }

  set languages(value) {
    this.setAttribute('languages', value)
  }

  get languages() {
    return this.getAttribute('languages') || [...new Set(navigator.languages.map(l => [l, l.split('-')[0]]).flat())].join(',')
  }

  set languagemode(value) {
    this.setAttribute('languagemode', value)
  }

  get languagemode() {
    return this.getAttribute('languagemode') || 'both'
  }

  set changemode(value) {
    this.setAttribute('changemode', value)
  }

  get changemode() {
    return this.getAttribute('changemode') || 'flyto'
  }

  set mapstyle(value) {
    this.setAttribute('mapstyle', value)
  }

  get mapstyle() {
    return this.getAttribute('mapstyle') || ''
  }

  set mapstyleurl(value) {
    this.setAttribute('mapstyleurl', value)
  }

  get mapstyleurl() {
    return this.getAttribute('mapstyleurl') || ''
  }

  set mapstylejson(value) {
    this.setAttribute('mapstylejson', value)
  }

  get mapstylejson() {
    return JSON.parse(this.getAttribute('mapstylejson') || 'false')
  }

  set loader(value) {
    this.setAttribute('loader', value)
  }

  get loader() {
    return this.getAttribute('loader') || 'pmtiles'
  }

  set terrain(value) {
    this.setAttribute('terrain', value)
  }

  get terrain() {
    return JSON.parse(this.getAttribute('terrain') || 'false')
  }

  set hillshade(value) {
    this.setAttribute('hillshade', value)
  }

  get hillshade() {
    return JSON.parse(this.getAttribute('hillshade') || 'false')
  }

  set contours(value) {
    this.setAttribute('contours', value)
  }

  get contours() {
    return JSON.parse(this.getAttribute('contours') || 'false')
  }

  set globe(value) {
    this.setAttribute('globe', value)
  }

  get globe() {
    return JSON.parse(this.getAttribute('globe') || 'false')
  }

  set attribution(value) {
    this.setAttribute('attribution', value)
  }

  get attribution() {
    return this.getAttribute('attribution') || 'minimal'
  }

  set cooperativegestures(value) {
    this.setAttribute('cooperativegestures', value)
  }

  get cooperativegestures() {
    return JSON.parse(this.getAttribute('cooperativegestures') || 'true')
  }

  set baseurl(value) {
    this.setAttribute('baseurl', value)
  }

  get baseurl() {
    return this.getAttribute('baseurl') || import.meta.url
  }

  set inspect(value) {
    this.setAttribute('inspect', value)
  }

  get inspect() {
    return JSON.parse(this.getAttribute('inspect') || 'false')
  }
}

customElements.define("maps-black", MapsBlack)
