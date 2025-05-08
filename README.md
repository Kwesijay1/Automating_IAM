# Automating IAM (Identity and Access Management) - Linux User Provisioning
This lab exercise assists learners to write a Bash script to automate Identity and Access  Management (IAM) tasks in Linux

This project automates the creation of Linux user accounts with email notifications. It reads user details from a CSV file, creates accounts with secure temporary passwords, forces password changes on first login, and sends credentials via email.

## ** Features**
- **Bulk user creation** from a CSV file
- **Secure password generation** (meets complexity requirements)
- **Email notifications** with temporary credentials
- **Logging** of all account creation activities
- **Group management** (creates groups if they don't exist)
- **Forces password change** on first login

---

## ** Prerequisites**
- **Linux system** (tested on Ubuntu)
- **Root/sudo access** (for user creation)
- **`mailutils`** (for sending emails)
- **CSV file** (`users.txt`) containing user details

---

## ** Setup & Installation**

### **1. Install Required Packages**
Ensure `mailutils` is installed for email notifications:
```bash
sudo apt update
sudo apt install -y mailutils
```

#### **Configure Mail Service (Postfix)**
During installation, you'll be prompted to configure Postfix:
- Select **"Internet Site"**  
- Enter your **mail server domain** (e.g., `yourdomain.com`)  

If you missed this step, reconfigure Postfix:
```bash
sudo dpkg-reconfigure postfix
```

#### **Test Email Sending**
Verify that emails work:
```bash
echo "Test email body" | mail -s "Test Subject" your-email@example.com
```
*(Check spam folder if the email doesn’t arrive.)*

---

### **2. Prepare the CSV File (`users.txt`)**
Create a CSV file with the following format:
```
username,fullname,group,email
jdoe,John Doe,engineering,john.doe@example.com
asmith,Alice Smith,marketing,alice.smith@example.com
```

### **3. Download the Script**
Save the script as `iam_setup.sh` in the `Automating_IAM` directory:
```bash
mkdir -p ~/Automating_IAM
cd ~/Automating_IAM
wget -O iam_setup.sh https://raw.githubusercontent.com/your-repo/Automating_IAM/main/iam_setup.sh
chmod +x iam_setup.sh
```

---

## ** Usage**
Run the script with the CSV file as input:
```bash
sudo ./iam_setup.sh users.txt
```

### **Expected Output**
- Users are created with temporary passwords.
- Passwords are stored securely in `/root/user_passwords.txt`.
- A log file (`user_creation.log`) is generated in the `Automating_IAM` directory.
- Users receive an email with their credentials.

---

## ** Files Generated**
| File | Purpose |
|------|---------|
| `/root/user_passwords.txt` | Stores temporary passwords securely (root-only) |
| `~/Automating_IAM/user_creation.log` | Logs all account creation activities |
| `users.txt` | Input CSV file with user details |

---

## ** Security Notes**
- **`/root/user_passwords.txt`** is restricted to root (`chmod 600`).
- **Passwords are temporary** and must be changed on first login.
- **Log files** are readable for auditing (`chmod 644`).

---

## ** Troubleshooting**
### **1. Email Not Sending?**
- Check Postfix logs:
  ```bash
  sudo tail -n 20 /var/log/mail.log
  ```
- Ensure `mailutils` is installed correctly.

### **2. User Creation Fails?**
- Check logs:
  ```bash
  cat ~/Automating_IAM/user_creation.log
  ```
- Verify CSV file formatting.

### **3. Permission Denied?**
- Run the script as root:
  ```bash
  sudo ./iam_setup.sh users.txt
  ```

---

 **Happy Automating!** 
