import React from "react";
import {requireNativeComponent,NativeModules,Platform,PermissionsAndroid,DeviceEventEmitter} from "react-native";

const RNPdfScanner = requireNativeComponent("RNPdfScanner");
const CameraManager = NativeModules.RNPdfScannerManager || {};

/**
 * 扫描照片,获取文档的边界点
 */
export default class DocumentScanner extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      permissionsAuthorized: Platform.OS === "ios"
    };
  }

  onPermissionsDenied = () => {
    if (this.props.onPermissionsDenied) this.props.onPermissionsDenied();
  };

  componentDidMount() {
    this.getAndroidPermissions();
    if (Platform.OS === "android") {
      const { onPictureTaken, onProcessing } = this.props;
      this.offOnPictureTaken = DeviceEventEmitter.addListener("onPictureTaken", onPictureTaken);
      this.offOnProcessingChange = DeviceEventEmitter.addListener("onProcessingChange", onProcessing);
    }
  }

  async getAndroidPermissions() {
    if (Platform.OS !== "android") return;
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
        PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE
      ]);

      if (granted["android.permission.READ_EXTERNAL_STORAGE"] === PermissionsAndroid.RESULTS.GRANTED && 
          granted["android.permission.WRITE_EXTERNAL_STORAGE"] === PermissionsAndroid.RESULTS.GRANTED){
            this.setState({ permissionsAuthorized: true });
          }else{
            this.onPermissionsDenied();
          } 
    } catch (err) {
      this.onPermissionsDenied();
    }
  }

  sendOnPictureTakenEvent(event) {
    return this.props.onPictureTaken(event.nativeEvent);
  }

  sendOnRectanleDetectEvent(event) {
    if (!this.props.onRectangleDetect) return null;
    return this.props.onRectangleDetect(event.nativeEvent);
  }

  getImageQuality() {
    if (!this.props.quality) return 1;
    if (this.props.quality > 1) return 1;
    if (this.props.quality < 0.1) return 0.1;
    return this.props.quality;
  }

  componentWillUnmount() {
    if (Platform.OS === "android") {
      if(this.offOnPictureTaken){
        this.offOnPictureTaken.remove();
      }
      if(this.offOnProcessingChange){
        this.offOnProcessingChange.remove();
      }
    }
  }

  capture() {
    if (this.state.permissionsAuthorized){
      CameraManager.capture();
    }
  }

  render() {
    if (!this.state.permissionsAuthorized) {
      return null
    }
    return (
      <RNPdfScanner
        {...this.props}
        onPictureTaken={this.sendOnPictureTakenEvent.bind(this)}
        onRectangleDetect={this.sendOnRectanleDetectEvent.bind(this)}
        useFrontCam={this.props.useFrontCam || false}
        brightness={this.props.brightness || 0}
        saturation={this.props.saturation || 1}
        contrast={this.props.contrast || 1}
        quality={this.getImageQuality()}
        detectionCountBeforeCapture={
          this.props.detectionCountBeforeCapture || 5
        }
        detectionRefreshRateInMS={this.props.detectionRefreshRateInMS || 50}
      />
    );
  }
}