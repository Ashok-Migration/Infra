var __extends = (this && this.__extends) || (function () {
    var extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import { BaseApplicationCustomizer } from '@microsoft/sp-application-base';
import * as strings from 'GlobalCustomStyleApplicationCustomizerStrings';
var LOG_SOURCE = 'GlobalCustomStyleApplicationCustomizer';
var GlobalCustomStyleApplicationCustomizer = /** @class */ (function (_super) {
    __extends(GlobalCustomStyleApplicationCustomizer, _super);
    function GlobalCustomStyleApplicationCustomizer() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    GlobalCustomStyleApplicationCustomizer.prototype.onInit = function () {
        Log.info(LOG_SOURCE, "Initialized " + strings.Title);
        var cssUrl = this.properties.cssurl;
        if (cssUrl) {
            // inject the style sheet
            var head = document.getElementsByTagName("head")[0] || document.documentElement;
            var customStyle = document.createElement("link");
            customStyle.href = cssUrl;
            customStyle.rel = "stylesheet";
            customStyle.type = "text/css";
            head.insertAdjacentElement("beforeEnd", customStyle);
        }
        return Promise.resolve();
    };
    __decorate([
        override
    ], GlobalCustomStyleApplicationCustomizer.prototype, "onInit", null);
    return GlobalCustomStyleApplicationCustomizer;
}(BaseApplicationCustomizer));
export default GlobalCustomStyleApplicationCustomizer;
//# sourceMappingURL=GlobalCustomStyleApplicationCustomizer.js.map