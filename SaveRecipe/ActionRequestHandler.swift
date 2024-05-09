//
//  ActionRequestHandler.swift
//  SaveRecipe
//
//  Created by nate parrott on 5/8/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

extension NSExtensionContext {
    func findHTML() async -> String? {
        for item in inputItems as! [NSExtensionItem] {
            if let attachments = item.attachments {
                for itemProvider in attachments {
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
                        if let plist = try? await itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier),
                           let doc = plist as? [String: Any],
                           let jsDict = doc[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any],
                           let html = jsDict["html"] as? String {
                            return html
                        }
                    }
                }
            }
        }
        return nil
    }
}

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    func beginRequest(with context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        // TODO

//        Task {
//            let html = try await
//        }
    }
    
    func itemLoadCompletedWithPreprocessingResults(_ javaScriptPreprocessingResults: [String: Any]) {
        // Here, do something, potentially asynchronously, with the preprocessing
        // results.
        
        // In this very simple example, the JavaScript will have passed us the
        // current background color style, if there is one. We will construct a
        // dictionary to send back with a desired new background color style.
        let bgColor: Any? = javaScriptPreprocessingResults["currentBackgroundColor"]
        if bgColor == nil ||  bgColor! as! String == "" {
            // No specific background color? Request setting the background to red.
            self.doneWithResults(["newBackgroundColor": "red"])
        } else {
            // Specific background color is set? Request replacing it with green.
            self.doneWithResults(["newBackgroundColor": "green"])
        }
    }
    
    func doneWithResults(_ resultsForJavaScriptFinalizeArg: [String: Any]?) {
        if let resultsForJavaScriptFinalize = resultsForJavaScriptFinalizeArg {
            // Construct an NSExtensionItem of the appropriate type to return our
            // results dictionary in.
            
            // These will be used as the arguments to the JavaScript finalize()
            // method.
            
            let resultsDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize]
            
            let resultsProvider = NSItemProvider(item: resultsDictionary as NSDictionary, typeIdentifier: UTType.propertyList.identifier)
            
            let resultsItem = NSExtensionItem()
            resultsItem.attachments = [resultsProvider]
            
            // Signal that we're complete, returning our results.
            self.extensionContext!.completeRequest(returningItems: [resultsItem], completionHandler: nil)
        } else {
            // We still need to signal that we're done even if we have nothing to
            // pass back.
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
        
        // Don't hold on to this after we finished with it.
        self.extensionContext = nil
    }

}
