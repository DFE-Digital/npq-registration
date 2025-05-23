import mermaid from 'mermaid';
import svgPanZoom from 'svg-pan-zoom';

mermaid.initialize({
  startOnLoad: false,
  deterministicIds: true,
  theme: "base",
  fontSize: "19px",
  themeVariables: {
    primaryColor: "#1D70B8",
    primaryTextColor: "#FFFFFF",
    primaryBorderColor: "#B1B4B6",
    actorBorder: "#B1B4B6",
    noteBkgColor: "#B1B4B6",
    noteBorderColor: "#B1B4B6",
    textColor: "#000000",
    fontFamily: '"GDS Transport", arial, sans-serif',
  },
});

mermaid.run({
  querySelector: ".mermaid",
  postRenderCallback: (id) => {
    const svg = document.querySelector(`#${id}`)
    const svgHeight = svg.parentElement.offsetHeight
    svg.style.height = svgHeight
    svgPanZoom(svg, {
      controlIconsEnabled: true,
      customEventsHandler: { init: () => {
        // Position controls in the bottom left.
        const controls = svg.querySelector("#svg-pan-zoom-controls")
        controls.setAttribute("transform", `translate(0, ${svgHeight - 75}) scale(0.75, 0.75)`)
      }, destroy: () => {}},
    })
  }
});
