<!-- start https://stackoverflow.com/a/15506705 -->
const addStyle = (() => {
  const style = document.createElement('style');
  document.head.append(style);
  return (styleString) => style.textContent = styleString;
})();
<!-- end https://stackoverflow.com/a/15506705 -->

const checkbox = document.getElementById("debug");
const localDebug = localStorage.getItem("debug");
if (localDebug !== null) {
  checkbox.checked = localDebug == "true";
}

function setOutline(value){
  if (value) {
    addStyle("* {outline: 1px dotted red;}");
  } else {
    addStyle("");
  }
}

setOutline(checkbox.checked);
function setDebug(value) {
  localStorage.setItem("debug", value.toString());
  setOutline(value);
}

checkbox.addEventListener("change", function () {
  setDebug(checkbox.checked);
});
