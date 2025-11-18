import datetime, json, os, subprocess, requests, time, traceback

# Define ANSI escape code constants vor clarity in the print commands below
RESET_FORMATTING = "\x1b[0m"
BOLD_BLUE = "\x1b[1;34m"
BOLD_RED = "\x1b[1;31m"
BOLD_GREEN = "\x1b[1;32m"
BOLD_YELLOW = "\x1b[1;33m"

print_command = lambda command='': print(f"⚙️ {BOLD_BLUE}Running: {command} {RESET_FORMATTING}")
print_error = lambda message, output='', duration='': print(f"❌ {BOLD_YELLOW}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")
print_info = lambda message: print(f"👉🏽 {BOLD_BLUE}{message}{RESET_FORMATTING}")
print_message = lambda message, output='', duration='': print(f"👉🏽 {BOLD_GREEN}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")
print_ok = lambda message, output='', duration='': print(f"✅ {BOLD_GREEN}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")
print_warning = lambda message, output='', duration='': print(f"⚠️ {BOLD_YELLOW}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")

class Output(object):
    def __init__(self, success, text):
        self.success = success
        self.text = text

        try:
            self.json_data = json.loads(text)
        except:
            self.json_data = json.loads("{}")   # return an empty JSON object if the output is not valid JSON rather than None as that makes consuming it easier this way


def get_current_subscription():
    try:
        output = run("az account show", "Retrieved az account", "Failed to get the current az account")

        if output.success and output.json_data:
            subscription_id = output.json_data['id']
            subscription_name = output.json_data['name']
            print_info(f"Using Subscription ID: {subscription_id} ({subscription_name})")
            return subscription_id
        else:
            print_error("No current subscription found.")
            return None
    except Exception as e:
        print_error(f"Error retrieving current subscription: {e}")
        return None

# Retrieves resources in a resource group
def get_resources(resource_group_name, config):
    if not resource_group_name:
        print_error("Missing resource group name parameter.")
        return

    resources = {}
    try:
        ## retrieve resource group location
        output = run(f"az group show --name {resource_group_name}")

        if output.success:
            print_info(f"Using existing resource group '{resource_group_name}'")
            output = run(f"az group show --name {resource_group_name} -o json", "Retrieved resource group ", "Failed to retrieve resource group")
            if output.success and output.json_data:
                resources['resourceGroupLocation'] = output.json_data["location"]

                ## retrieve resources
                output = run(f'az resource list -g {resource_group_name} -o json', "Listed resources", "Failed to list resources")
                if output.success and output.json_data:
                    for resource in output.json_data:
                        match resource["type"].lower():
                            case "microsoft.operationalinsights/workspaces":
                                resources['logAnalyticsResourceId'] = resource["id"]
                                resources['logAnalyticsResourceName'] = resource["name"]
                            case "microsoft.insights/components":
                                resources['appInsightsResourceId'] = resource["id"]
                                resources['appInsightsResourceName'] = resource["name"]
                                output = run(f'az resource show -g {resource_group_name} -n {resource["name"]} --resource-type "microsoft.insights/components" -o json', "Retrieved App Insights resource", "Failed to retrieve App Insights resource")
                                if output.success and output.json_data:
                                    resources['appInsightsInstrumentationKey'] = output.json_data["properties"]["InstrumentationKey"]
                            case "microsoft.cognitiveservices/accounts":
                                resources['foundryResourceId'] = resource["id"]
                                resources['foundryResourceName'] = resource["name"]
                            case "microsoft.cognitiveservices/accounts/projects":
                                resources['foundryProjectId'] = resource["id"]
                                resources['foundryProjectName'] = resource["name"]
                            case "microsoft.apimanagement/service":
                                resources['apimResourceId'] = resource["id"]
                                resources['apimResourceName'] = resource["name"]
                                resources['apimPrincipalId'] = resource["identity"]["principalId"]
        else:
            return config

    except Exception as e:
        print_error(f"Error retrieving resources: {e}")

    return resources

def print_response(response):
    print("Response headers: ", response.headers)

    if (response.status_code == 200):
        print_ok(f"Status Code: {response.status_code}")
        data = json.loads(response.text)
        print(json.dumps(data, indent=4))
    else:
        print_warning(f"Status Code: {response.status_code}")
        print(response.text)

def print_response_code(response):
    # Check the response status code and apply formatting
    if 200 <= response.status_code < 300:
        status_code_str = f"{BOLD_GREEN}{response.status_code} - {response.reason}{RESET_FORMATTING}"
    elif response.status_code >= 400:
        status_code_str = f"{BOLD_RED}{response.status_code} - {response.reason}{RESET_FORMATTING}"
    else:
        status_code_str = str(response.status_code)

    # Print the response status with the appropriate formatting
    print(f"Response status: {status_code_str}")

# Simple: print full error body (JSON if available, else raw text)
def print_full_http_error(response):
    try:
        data = response.json()
        print_error("Request failed. Full JSON body:", json.dumps(data, indent=2))
        # If ARM-style error present, surface message too
        if isinstance(data, dict) and isinstance(data.get("error"), dict):
            code = data["error"].get("code", "")
            msg = data["error"].get("message", "")
            if msg or code:
                print_error(f"Service error:", f"{code} - {msg}")
    except ValueError:
        print_error("Request failed. Full text body:", response.text or "")

def run(command, ok_message = '', error_message = '', print_output = False, print_command_to_run = True):
    if print_command_to_run:
        print_command(command)

    start_time = time.time()

    try:
        completed_process = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        output_text = completed_process.stdout
        success = completed_process.returncode == 0
    except subprocess.CalledProcessError as e:
        output_text = e.output.decode("utf-8")
        success = False

    minutes, seconds = divmod(time.time() - start_time, 60)

    print_message = print_ok if success else print_error

    if (ok_message or error_message):
        print_message(ok_message if success else error_message, output_text if not success or print_output  else "", f"[{int(minutes)}m:{int(seconds)}s]")

    return Output(success, output_text)

def update_api_policy(subscription_id, resource_group_name, apim_service_name, api_id, policy_xml):
    # We first need to obtain an access token for the REST API
    output = run(f"az account get-access-token --resource https://management.azure.com/",
        f"Successfully obtained access token", f"Failed to obtain access token")

    if output.success and output.json_data:
        access_token = output.json_data['accessToken']

        print("Updating the API policy...")
        # https://learn.microsoft.com/en-us/rest/api/apimanagement/api-policy/create-or-update?view=rest-apimanagement-2024-06-01-preview
        url = f"https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{apim_service_name}/apis/{api_id}/policies/policy?api-version=2024-06-01-preview"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        }

        body = {
            "properties": {
                "format": "rawxml",
                "value": policy_xml
            }
        }

        response = requests.put(url, headers = headers, json = body)
        if 200 <= response.status_code < 300:
            print_response_code(response)
        else:
            print_response_code(response)
            print_full_http_error(response)

def update_api_operation_policy(subscription_id, resource_group_name, apim_service_name, api_id, operation_id, policy_xml):
    # We first need to obtain an access token for the REST API
    output = run(f"az account get-access-token --resource https://management.azure.com/",
        f"Successfully obtained access token", f"Failed to obtain access token")

    if output.success and output.json_data:
        access_token = output.json_data['accessToken']

        print("Updating the API policy...")
        # https://learn.microsoft.com/en-us/rest/api/apimanagement/api-policy/create-or-update?view=rest-apimanagement-2024-06-01-preview
        url = f"https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{apim_service_name}/apis/{api_id}/operations/{operation_id}/policies/policy?api-version=2024-06-01-preview"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        }

        body = {
            "properties": {
                "format": "rawxml",
                "value": policy_xml
            }
        }

        response = requests.put(url, headers = headers, json = body)
        print_response_code(response)

def get_debug_credentials(apim_service_id, api_id, expire_after = 'PT1H') -> str | None:
    request = {
        "credentialsExpireAfter": expire_after,
        "apiId": f"{apim_service_id}/apis/{api_id}",
        "purposes": ["tracing"]
    }
    output = run(f"az rest --method post --uri {apim_service_id}/gateways/managed/listDebugCredentials?api-version=2023-05-01-preview --body \"{str(request)}\"",
            "Retrieved APIM debug credentials", "Failed to get the APIM debug credentials")
    return output.json_data['token'] if output.success and output.json_data else None

def get_trace(apim_service_id, trace_id) -> str | None:
    request = {
        "traceId": trace_id
    }
    output = run(f"az rest --method post --uri {apim_service_id}/gateways/managed/listTrace?api-version=2023-05-01-preview --body \"{str(request)}\"",
            "Retrieved trace details", "Failed to get the trace details")
    return output.json_data if output.success and output.json_data else None
