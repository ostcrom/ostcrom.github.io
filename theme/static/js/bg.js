
function changeBackground(imgPath) {
  document.body.style.backgroundImage = "url('/theme/images/" + imgPath + "')"
}

function getRandomInt(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

imgArray = ["tux.png", "texas.png"]

bgIndex = getRandomInt(1, imgArray.length) - 1
changeBackground(imgArray[bgIndex])
