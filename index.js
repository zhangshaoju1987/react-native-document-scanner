import DocumentScanner from "./DocumentScanner";
import DocumentCropper from "./DocumentCropper";
import { NativeModules } from "react-native";


/**
 * 检测文档边界
 * @param {String} imageUri
 * @param {Function} callback 
 */
function detectDocument(imageUri,callback){
    if(!imageUri || !imageUri.startsWith("file://")){
        throw new Error("图片路径必须以file://开头")
    }
    NativeModules.RNPdfScannerManager.detectDocument(imageUri,callback);
}

/**
 * 旋转图片(每次顺时针旋转90度)
 * 可以是file开头的文件路径或者是纯base64的图片内容
 * @param {String} imageUri 
 * @param {Function} callback 
 */
function rotate90(imageUri,callback){
    if(!imageUri || !imageUri.startsWith("file://")){
        throw new Error(`图片路径必须以file://开头,[file://]${imageUri}`)
    }
    NativeModules.RNPdfScannerManager.rotateImage(imageUri,callback);
}

/**
 * 缩放图片
 * @param {String} imageUri file://开头的uri
 * @param {Number} scale file://开头的uri
 * @param {Function} callback 
 */
function scale(imageUri,scale = 0.25,callback){
    if(!imageUri || !imageUri.startsWith("file://")){
        throw new Error(`图片路径必须以file://开头,[file://]${imageUri}`)
    }
    NativeModules.RNPdfScannerManager.scaleImage(imageUri,scale,callback);
}
/**
 * 生成缩率图
 * @param {String} imageUri 
 * @param {Number} scale 
 * @param {Number} quality 
 * @param {Function} callback 
 */
function thumbnail(imageUri,scale=0.25,quality=0.8,callback){
    if(!imageUri || !imageUri.startsWith("file://")){
        throw new Error(`图片路径必须以file://开头,[file://]${imageUri}`)
    }
    NativeModules.RNPdfScannerManager.thumbnail(imageUri,scale,quality,callback);
}

/**
 * 导出文档扫描器和图片裁剪器
 */
export {DocumentScanner,DocumentCropper,detectDocument,rotate90,scale,thumbnail}