//
//  KYCCountrySelectionController.swift
//  Blockchain
//
//  Created by Maurice A. on 7/9/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import UIKit

private protocol HTTPError: Error {
    var debugDescription: String { get }
}

/// Country selection screen in KYC flow
final class KYCCountrySelectionController: UIViewController, KYCOnboardingNavigation {

    private typealias Countries = [KYCCountry]

    // MARK: - Properties

    private enum HTTPURLResponseError: HTTPError {
        case badResponse, badStatusCode(code: Int)
        var debugDescription: String {
            switch self {
            case .badResponse: return "Bad response."
            case .badStatusCode(let code): return "The server returned a bad response: \(code)."
            }
        }
    }

    private enum HTTPRequestPayloadError: HTTPError {
        case badData, emptyData, invalidMimeType(type: String)
        var debugDescription: String {
            switch self {
            case .badData: return "The data returned by the server was bad."
            case .emptyData: return "The data returned by the server was empty."
            case .invalidMimeType(let type): return "The server returned an invalid MIME type: \(type)."
            }
        }
    }

    private var countries: Countries?

    var segueIdentifier: String? = "promptForContactDetails"

    // MARK: - IBOutlets

    @IBOutlet var countryPicker: UIPickerView!
    @IBOutlet var primaryButton: PrimaryButton!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString(
            "Select Your Country",
            comment: "The title of the navigation item in the country selection screen."
        )
        fetchListOfCountries()
    }

    // MARK: - Private Methods

    private func decode(json: Data) {
        do {
            countries = try JSONDecoder().decode([KYCCountry].self, from: json)
        } catch {
            handlePayloadError(.badData)
        }
    }

    // TODO: replace url with https://api.dev.blockchain.info/nabu-app/kyc/config/countries
    private func fetchListOfCountries() {
        let url = URL(string: "https://www.mocky.io/v2/5b5a709e3100002b009a87ec")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                self.handleClientError(error); return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                self.handleServerError(.badResponse); return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.handleServerError(.badStatusCode(code: httpResponse.statusCode)); return
            }
            if let mimeType = httpResponse.mimeType {
                guard mimeType == "application/json" else {
                    self.handlePayloadError(.invalidMimeType(type: mimeType)); return
                }
            }
            guard let responseData = data else {
                self.handlePayloadError(HTTPRequestPayloadError.emptyData); return
            }
            self.decode(json: responseData)
        }
        task.resume()
    }

    private func handleClientError(_ error: Error) {
        fatalError(error.localizedDescription)
    }

    /// Handles errors related to the request payload
    ///
    /// - Parameter error: the payload error
    private func handlePayloadError(_ error: HTTPRequestPayloadError) {
        AlertViewPresenter.shared.standardError(
            message: "There was a problem with your request. Please try again in a moment.",
            title: "Error",
            in: self
        )
    }

    /// Handles errors caused on the server-side
    ///
    /// - Parameter error: the server-side error
    private func handleServerError(_ error: HTTPURLResponseError) {
        AlertViewPresenter.shared.standardError(
            message: "There was a problem with your request. Please try again in a moment.",
            title: "Error",
            in: self
        )
    }

    // MARK: - Actions

    @IBAction func primaryButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: segueIdentifier!, sender: self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: implement method body
    }
}

// MARK: - UIPickerViewDataSource
extension KYCCountrySelectionController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let count = countries?.count else { return 0 }
        return count
    }
}

// MARK: - UIPickerViewDelegate
extension KYCCountrySelectionController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // TODO: implement method body
        // primaryButton.isEnabled = true
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return nil
    }
}
