import io
import json
import logging
import os
import random
import shutil
import string
import tempfile
import zipfile
from datetime import datetime, timezone
from moviepy.editor import VideoFileClip
from PIL import Image
from sqlalchemy import text, ForeignKey
import gridfs
from bson.objectid import ObjectId
from flask import Flask, abort, request, send_file, jsonify, render_template, Response, current_app, make_response
from flask_cors import CORS, cross_origin
from flask_mail import Mail, Message
from flask_pymongo import PyMongo
from flask_restful import Api, Resource
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import relationship
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import NUDITYDETECTION
from PROFANITY_FILTER import check_profanity_and_similarity
from flask_jwt_extended import jwt_required, get_jwt_identity
from flask_socketio import SocketIO, emit ,join_room, leave_room

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'mp4', 'avi', 'mov', 'mkv', 'webm'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
# Flask application setup
app = Flask(__name__)
app.config["MONGO_URI"] = "mongodb://localhost:27017/DouneMDB"  # Replace with your MongoDB URI
app.config['SQLALCHEMY_DATABASE_URI'] = r'mssql+pyodbc://sa:Phamthangta90@DESKTOP-6B2BUVI\SQLEXPRESS/Doune?driver=ODBC+Driver+17+for+SQL+Server'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['MAIL_SERVER'] = 'smtp.googlemail.com'  # Replace with your SMTP server
app.config['MAIL_PORT'] = 587  # Use 465 for SSL
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'dounecompany@gmail.com'  # Your email
app.config['MAIL_PASSWORD'] = 'zasa vbpy arko snov'  # Your email password
app.config['MAIL_DEFAULT_SENDER'] = 'dounecompany@gmail.com'  # Default sender
CORS(app)  # Enable CORS

# Initialize databases and mail
mongo = PyMongo(app)
api = Api(app)
fs = gridfs.GridFS(mongo.db)
fs_search = mongo.db['fs.search']
fs_messenger = mongo.db['fs.messenger']
db = SQLAlchemy(app)
mail = Mail(app)
socketio = SocketIO(app, cors_allowed_origins="*")


#MESSENGER

@app.route('/send_message', methods=['POST'])
def send_message():
    data = request.json
    sender_id = data.get('sender_id')
    receiver_id = data.get('receiver_id')
    message_text = data.get('message')

    if sender_id is None or receiver_id is None:
        return jsonify({'error': 'Missing sender_id or receiver_id'}), 400

    try:
        sender_id = int(sender_id)
        receiver_id = int(receiver_id)
    except ValueError:
        return jsonify({'error': 'Invalid sender or receiver ID'}), 400

    if not message_text:
        return jsonify({'error': 'Missing message text'}), 400

    # Ensure the sender and receiver are valid users
    sender = Users.query.get(sender_id)
    receiver = Users.query.get(receiver_id)

    if not sender or not receiver:
        return jsonify({'error': 'Sender or receiver not found'}), 404

    # Create or update the conversation
    conversation = fs_messenger.find_one({
        '$or': [
            {'participants': [sender_id, receiver_id]},
            {'participants': [receiver_id, sender_id]}
        ]
    })

    if not conversation:
        # Create a new conversation
        conversation = {
            'participants': [sender_id, receiver_id],
            'messages': []
        }
        fs_messenger.insert_one(conversation)

    # Add the new message to the conversation
    message = {
        'sender_id': sender_id,
        'text': message_text,
        'timestamp': datetime.now(timezone.utc)
    }
    fs_messenger.update_one(
        {'_id': conversation['_id']},
        {'$push': {'messages': message}}
    )

    # Emit the new message event to both the sender and the receiver
    new_message_data = {
        'sender_id': sender_id,
        'receiver_id': receiver_id,
        'text': message_text,
        'timestamp': message['timestamp'].isoformat()
    }
    socketio.emit('new_message', new_message_data, room=str(receiver_id))
    socketio.emit('new_message', new_message_data, room=str(sender_id))

    # Emit the update messenger list event
    socketio.emit('update_messenger_list', {'user_id': sender_id}, room=str(sender_id))
    socketio.emit('update_messenger_list', {'user_id': receiver_id}, room=str(receiver_id))


    return jsonify({'status': 'Message sent successfully'}), 200

@socketio.on('request_messenger_list')
def handle_request_messenger_list(data):
    user_id = data.get('user_id')
    if user_id is None:
        emit('error', {'error': 'Missing user_id'})
        return

    try:
        user_id = int(user_id)
    except ValueError:
        emit('error', {'error': 'Invalid user ID'})
        return

    # Lấy danh sách tin nhắn của người dùng
    conversations = fs_messenger.find({'participants': user_id})
    result = []
    for conversation in conversations:
        other_participant = next((p for p in conversation['participants'] if p != user_id), None)
        if other_participant is None:
            continue

        if conversation.get('messages'):
            last_message = conversation['messages'][-1]
            result.append({
                'contact_id': other_participant,
                'last_message': last_message['text'],
                'timestamp': last_message['timestamp'].isoformat()  # Convert datetime to string
            })

    emit('messenger_list', result, room=str(user_id))

    # Lấy danh sách tin nhắn của người dùng
    conversations = fs_messenger.find({'participants': user_id})
    result = []
    for conversation in conversations:
        other_participant = next((p for p in conversation['participants'] if p != user_id), None)
        if other_participant is None:
            continue

        if conversation.get('messages'):
            last_message = conversation['messages'][-1]
            result.append({
                'contact_id': other_participant,
                'last_message': last_message['text'],
                'timestamp': last_message['timestamp']
            })

    emit('messenger_list', result, room=str(user_id))

@app.route('/Get_User_Messenger_List', methods=['GET'])
def get_user_messenger_list():
    user_id = request.args.get('user_id')

    if user_id is None:
        return jsonify({'error': 'Missing user_id'}), 400

    try:
        user_id = int(user_id)
    except ValueError:
        return jsonify({'error': 'Invalid user ID'}), 400

    # Find all conversations involving the user
    conversations = fs_messenger.find({
        'participants': user_id
    })

    if not conversations:
        return jsonify({'error': 'No conversations found for the user'}), 404

    result = []
    for conversation in conversations:
        # Find the other participant
        other_participant = next((p for p in conversation['participants'] if p != user_id), None)
        if other_participant is None:
            continue

        # Get the last message in the conversation
        if conversation.get('messages'):
            last_message = conversation['messages'][-1]
            result.append({
                'contact_id': other_participant,
                'last_message': last_message['text'],
                'timestamp': last_message['timestamp'].isoformat()  # Convert datetime to string
            })

    if not result:
        return jsonify({'error': 'No messages found'}), 404

    return jsonify(result), 200

@app.route('/get_conversation', methods=['GET'])
def get_conversation():
    user_id = request.args.get('user_id')
    contact_id = request.args.get('contact_id')

    if not user_id or not contact_id:
        return jsonify({'error': 'Missing user_id or contact_id'}), 400

    try:
        user_id = int(user_id)
        contact_id = int(contact_id)
    except ValueError:
        return jsonify({'error': 'user_id and contact_id must be integers'}), 400

    # Find the conversation
    conversation = fs_messenger.find_one({
        '$or': [
            {'participants': [user_id, contact_id]},
            {'participants': [contact_id, user_id]}
        ]
    })

    if not conversation:
        return jsonify({'error': 'Conversation not found'}), 404

    # Convert datetime to string for all messages
    messages = conversation.get('messages', [])
    for message in messages:
        message['timestamp'] = message['timestamp'].isoformat()

    # Return all messages
    return jsonify(messages), 200


@socketio.on('join')
def on_join(data):
    user_id = data['user_id']
    room = str(user_id)
    join_room(room)
    emit('status', {'msg': f'User {user_id} has entered the room.'}, room=room)

@socketio.on('leave')
def on_leave(data):
    user_id = data['user_id']
    room = str(user_id)
    leave_room(room)
    emit('status', {'msg': f'User {user_id} has left the room.'}, room=room)
#======================================================================================================================================
# UploadVideo resource


@app.route('/delete_video/<file_id>', methods=['DELETE'])
def delete_video(file_id):
    try:
        # Convert file_id to ObjectId
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"message": "Invalid file_id format"}), 400

    # Find the video file in GridFS
    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})
    if not file_record:
        return jsonify({"message": "Video not found"}), 404

    # Delete the video file from GridFS
    mongo.db.fs.files.delete_one({'_id': file_id_obj})
    mongo.db.fs.chunks.delete_many({'files_id': file_id_obj})

    # Delete the thumbnail if it exists
    thumbnail_id = file_record.get('metadata', {}).get('thumbnail_id')
    if thumbnail_id:
        try:
            thumbnail_id_obj = ObjectId(thumbnail_id)
            fs_thumbnail.delete(thumbnail_id_obj)
        except Exception as e:
            return jsonify({"message": f"Error deleting thumbnail: {str(e)}"}), 500

    return jsonify({"message": "Video and thumbnail deleted successfully"}), 200

app.add_url_rule('/delete_video/<file_id>', view_func=delete_video, methods=['DELETE'])


class ReviewVideo(Resource):
    def post(self):
        file_id = request.form.get('file_id')
        action = request.form.get('action')  # Expected values: 'approve' or 'reject'

        if not file_id or action not in ['approve', 'reject']:
            return {"message": "Invalid request. 'file_id' and 'action' are required."}, 400

        file_record = fs.find_one({"_id": ObjectId(file_id), "metadata.status": "waiting_for_approval"})

        if not file_record:
            return {"message": "File not found or not pending approval."}, 404

        new_status = 'approved' if action == 'approve' else 'rejected'
        fs.update_one({"_id": ObjectId(file_id)}, {"$set": {"metadata.status": new_status}})

        return {"message": f"File has been {new_status}."}, 200

api.add_resource(ReviewVideo, '/review')

# UserSignUp DTO

class UserSignUpDto:
    def __init__(self, email, password, date_of_birth):
        self.Email = email
        self.Password = password
        self.DateOfBirth = date_of_birth

class UserSignUp(Resource):
    def post(self):
        data = request.json
        if not all(k in data for k in ("Email", "Password", "DateOfBirth")):
            return {"error": "Email, Password, and DateOfBirth are required."}, 400

        sign_up_dto = UserSignUpDto(
            email=data['Email'],
            password=data['Password'],
            date_of_birth=data['DateOfBirth']  # Expecting in ISO format
        )

        # Generate a random unique username
        username = self.generate_unique_username()

        user = Users(
            Email=sign_up_dto.Email,
            Password=generate_password_hash(sign_up_dto.Password),  # Hash the password
            DateOfBirth=sign_up_dto.DateOfBirth,
            Username=username,
            FullName="user"+username,
            Gender="DefaultGender",
            ProfilePicture="",  # Updated default profile picture path
            Bio='',
            CreatedAt=datetime.now(timezone.utc),
            UpdatedAt="",
            UpdatedAtUsername="",
            Follower=0,
            Point=0,
            Following=0,
            Verified=0,
            isBanned=0
        )
        db.session.add(user)
        db.session.commit()
        message = json.dumps({'User': data})
        return Response(message, status=201, mimetype='application/json')

    def generate_unique_username(self):
        while True:
            # Generate a random username
            username = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
            # Check if the username already exists
            if not Users.query.filter_by(Username=username).first():
                return username

# Model Người dùng
class Users(db.Model):
    __tablename__ = 'Users'

    UserID = db.Column(db.Integer, primary_key=True)
    Username = db.Column(db.String(50))
    Password = db.Column(db.String(100), nullable=False)
    Email = db.Column(db.String(100), nullable=False, unique=True)
    FullName = db.Column(db.String(100))
    DateOfBirth = db.Column(db.String(10))
    Gender = db.Column(db.String(10))
    ProfilePicture = db.Column(db.String(255))
    Bio = db.Column(db.String(255))
    CreatedAt = db.Column(db.DateTime, default=datetime.now(timezone.utc))
    UpdatedAt = db.Column(db.DateTime, default=datetime.now(timezone.utc), onupdate=datetime.now(timezone.utc))
    UpdatedAtUsername = db.Column(db.String(50))  # Thêm cột UpdatedAtUsername
    Follower = db.Column(db.BigInteger, default=0)
    Point = db.Column(db.BigInteger, default=0)
    Following = db.Column(db.BigInteger, default=0)
    Verified = db.Column(db.Boolean, default=False)
    isBanned = db.Column(db.Boolean, default=False)
    ban_reason_id = db.Column(db.Integer, db.ForeignKey('BanReasons.id'), nullable=True)

    # Mối quan hệ
    ban_reason = db.relationship('BanReason', backref='users', lazy=True)

    def as_dict(self):
        return {column.name: getattr(self, column.name) for column in self.__table__.columns}

    def ban_user(self, reason_id=None):
        self.isBanned = True
        self.ban_reason_id = reason_id  # Gán lý do cấm nếu có
        db.session.commit()

    def unban_user(self):
        self.isBanned = False
        self.ban_reason_id = None  # Xóa lý do cấm
        db.session.commit()
#Model REPORT
@app.route('/report_user', methods=['POST'])
def report_user():
    data = request.json
    user_id = data.get('user_id')
    reason = data.get('reason')

    if not user_id or not reason:
        return jsonify({"error": "User ID and reason are required."}), 400

    user = Users.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    report = {
        "user_id": user_id,
        "user_full_name": user.FullName,
        "user_name": user.Username,
        "time": datetime.now(timezone.utc),
        "reason": reason
    }

    mongo.db.UserReport.insert_one(report)
    return jsonify({"message": "User reported successfully"}), 201

@app.route('/report_media', methods=['POST'])
def report_media():
    data = request.json
    media_id = data.get('media_id')
    reason = data.get('reason')

    if not media_id or not reason:
        return jsonify({"error": "Media ID and reason are required."}), 400

    try:
        media_id_obj = ObjectId(media_id)
    except Exception as e:
        return jsonify({"error": "Invalid media_id format"}), 400

    file_record = mongo.db.fs.files.find_one({'_id': media_id_obj})
    if not file_record:
        return jsonify({"error": "Media not found"}), 404

    user_id = file_record.get('metadata', {}).get('user_id')
    user = Users.query.get(user_id) if user_id else None
    user_info = {
        "UserId": user.UserID,
        "FullName": user.FullName,
        "Username": user.Username,
        "ProfilePicture": user.ProfilePicture,
        "Verified": user.Verified
    } if user else {}

    report = {
        "media_id": media_id,
        "user_info": user_info,
        "time": datetime.now(timezone.utc),
        "reason": reason
    }

    mongo.db.MediaReport.insert_one(report)
    return jsonify({"message": "Media reported successfully"}), 201
# Model Lý do cấm
class BanReason(db.Model):
    __tablename__ = 'BanReasons'
    id = db.Column(db.Integer, primary_key=True)
    reason = db.Column(db.String(255), nullable=False)

    def as_dict(self):
        return {column.name: getattr(self, column.name) for column in self.__table__.columns}

# Tài nguyên Cấm người dùng
class BanUser(Resource):
    def post(self, user_id):
        data = request.get_json()
        reason_id = data.get('reason_id')  # Lấy reason_id từ yêu cầu

        user = Users.query.get(user_id)
        if not user:
            return {'message': 'User not found'}, 404

        user.ban_user(reason_id)
        return {'message': 'User banned successfully'}, 200

# Tài nguyên Mở cấm người dùng
class UnbanUser(Resource):
    def post(self, user_id):
        user = Users.query.get(user_id)
        if not user:
            return {'message': 'User not found'}, 404

        user.unban_user()
        return {'message': 'User unbanned successfully'}, 200

# Model Người dùng bị chặn
class BlockedUser(db.Model):
    __tablename__ = 'BlockedUsers'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('Users.UserID'), nullable=False)
    blocked_user_id = db.Column(db.Integer, db.ForeignKey('Users.UserID'), nullable=False)

    def as_dict(self):
        return {column.name: getattr(self, column.name) for column in self.__table__.columns}

# Tài nguyên Chặn người dùng
class BlockUser(Resource):
    def post(self):
        data = request.get_json()
        user_id = data.get('user_id')
        blocked_user_id = data.get('blocked_user_id')

        if user_id is None or blocked_user_id is None:
            return {'message': 'user_id and blocked_user_id are required'}, 400

        new_block = BlockedUser(user_id=user_id, blocked_user_id=blocked_user_id)
        db.session.add(new_block)
        db.session.commit()

        return {'message': 'User blocked successfully'}, 201

# Tài nguyên Mở chặn người dùng
class UnblockUser(Resource):
    def delete(self):
        data = request.get_json()
        user_id = data.get('user_id')
        blocked_user_id = data.get('blocked_user_id')

        if user_id is None or blocked_user_id is None:
            return {'message': 'user_id and blocked_user_id are required'}, 400

        block_entry = BlockedUser.query.filter_by(user_id=user_id, blocked_user_id=blocked_user_id).first()
        if not block_entry:
            return {'message': 'Block entry not found'}, 404

        try:
            db.session.delete(block_entry)
            db.session.commit()
        except Exception as e:
            db.session.rollback()  # Rollback in case of error
            return {'message': 'Error unblocking user'}, 500

        return {'message': 'User unblocked successfully'}, 200

# Tài nguyên Kiểm tra người dùng bị chặn
class CheckBlocked(Resource):
    def get(self, user_id, blocked_user_id):
        block_entry = BlockedUser.query.filter_by(user_id=user_id, blocked_user_id=blocked_user_id).first()
        if block_entry:
            return {'is_blocked': True}, 200
        return {'is_blocked': False}, 200

# Tài nguyên Lấy danh sách người dùng bị chặn
class BlockedUsersList(Resource):
    def get(self, user_id):
        # Query the database for blocked users of the given user_id
        blocked_users = BlockedUser.query.filter_by(user_id=user_id).all()

        if blocked_users:
            blocked_users_data = []
            for blocked_user in blocked_users:
                blocked_user_info = Users.query.get(blocked_user.blocked_user_id)
                if blocked_user_info:
                    blocked_users_data.append({
                        'id': blocked_user_info.UserID,
                        'username': blocked_user_info.Username,
                        'full_name': blocked_user_info.FullName,
                        'profile_picture': blocked_user_info.ProfilePicture,
                    })
            return jsonify({"blocked_users": blocked_users_data})
        else:
            return jsonify({"blocked_users": []})  # No blocked users

# Tài nguyên Kiểm tra người dùng bị cấm
class CheckBan(Resource):
    def get(self, user_id):
        user = Users.query.get(user_id)
        if not user:
            return {'message': 'User not found'}, 404

        if user.isBanned:
            return {'is_banned': True}, 200
        return {'is_banned': False}, 200

# Tài nguyên Lý do cấm
class BanReasons(Resource):
    def get(self):
        reasons = BanReason.query.all()
        return {'reasons': [reason.as_dict() for reason in reasons]}, 200

    def post(self):
        data = request.get_json()
        reason = data.get('reason')
        if not reason:
            return {'message': 'Reason is required'}, 400

        new_reason = BanReason(reason=reason)
        db.session.add(new_reason)
        db.session.commit()
        return {'message': 'Reason added successfully'}, 201

@app.route('/api/support-request', methods=['POST'])
def save_support_request():
    full_name = request.form.get('FullName')
    email = request.form.get('Email')
    message = request.form.get('Message')
    images = request.files.getlist('Image')  # Nhận danh sách các tệp hình ảnh

    # Kiểm tra thông tin
    if not full_name or not email or not message:
        return jsonify({'error': 'Vui lòng cung cấp đầy đủ thông tin!'}), 400

    # Kiểm tra loại tệp và lưu hình ảnh
    image_ids = []
    for image in images:
        if not allowed_file(image.filename):
            return jsonify({'error': f'Tệp {image.filename} không hợp lệ!'}), 400
        image_id = fs.put(image, filename=image.filename)  # Lưu tệp vào GridFS
        image_ids.append(str(image_id))  # Thêm ID vào danh sách

    # Lưu thông tin yêu cầu vào collection fs.support
    support_request = {
        "FullName": full_name,
        "Email": email,
        "Message": message,
        "ImageIds": image_ids  # Lưu danh sách ID hình ảnh
    }
    mongo.db['fs.support'].insert_one(support_request)

    return jsonify({'message': 'Yêu cầu hỗ trợ đã được lưu!', 'id': str(support_request['_id']), 'ImageIds': image_ids}), 200

@app.route('/api/identity-verification', methods=['POST'])
def save_identity_verification_request():
    full_name = request.form.get('FullName')
    email = request.form.get('Email')
    link_to_article = request.form.get('LinkToArticle')  # Đổi Message thành LinkToArticle
    images = request.files.getlist('Image')  # Nhận danh sách các tệp hình ảnh
    # Kiểm tra thông tin
    if not full_name or not email or not link_to_article:
        return jsonify({'error': 'Vui lòng cung cấp đầy đủ thông tin!'}), 400

    # Kiểm tra loại tệp và lưu hình ảnh
    image_ids = []
    for image in images:
        if not allowed_file(image.filename):
            return jsonify({'error': f'Tệp {image.filename} không hợp lệ!'}), 400
        image_id = fs.put(image, filename=image.filename)  # Lưu tệp vào GridFS
        image_ids.append(str(image_id))  # Thêm ID vào danh sách

    # Lưu thông tin yêu cầu vào collection fs.identity_verification
    identity = {
        "FullName": full_name,
        "Email": email,
        "LinkToArticle": link_to_article,  # Lưu LinkToArticle
        "ImageIds": image_ids  # Lưu danh sách ID hình ảnh
    }
    mongo.db['fs.identity_verification'].insert_one(identity)  # Đổi sang identity

    return jsonify({'message': 'Yêu cầu hỗ trợ đã được lưu!', 'id': str(identity['_id']), 'ImageIds': image_ids}), 200




# Tài nguyên lấy lý do cấm của người dùng
class UserBanReason(Resource):
    def get(self, user_id):
        user = Users.query.get(user_id)
        if not user:
            return {'message': 'User not found'}, 404

        if user.isBanned:
            ban_reason = BanReason.query.filter_by(id=user.ban_reason_id).first()
            if ban_reason:
                return {'user_id': user_id, 'ban_reason': ban_reason.reason}, 200
            else:
                return {'user_id': user_id, 'message': 'No reason provided'}, 200
        else:
            return {'user_id': user_id, 'message': 'User is not banned'}, 200

# Đăng ký các endpoint
api.add_resource(UserBanReason, '/user/<int:user_id>/ban-reason')
api.add_resource(BanUser, '/ban/<int:user_id>')
api.add_resource(UnbanUser, '/unban/<int:user_id>')
api.add_resource(BlockUser, '/block')
api.add_resource(UnblockUser, '/unblock')
api.add_resource(CheckBlocked, '/check_blocked/<int:user_id>/<int:blocked_user_id>')
api.add_resource(CheckBan, '/check_ban/<int:user_id>')
api.add_resource(BanReasons, '/ban_reasons')
api.add_resource(BlockedUsersList, '/list_blocked_users/<int:user_id>')

@app.route('/get_user_name/<string:username>', methods=['GET'])
def get_user(username):
    # Query để lấy thông tin người dùng theo username
    user = Users.query.filter_by(Username=username).first()

    if user is None:
        return jsonify({"error": "User not found"}), 404

    return jsonify(user.as_dict()), 200


@app.route('/update_username/<int:user_id>', methods=['PUT'])
def update_username(user_id):
    # Get the JSON data from the request
    data = request.get_json()

    # Check if 'username' is in the request data
    if 'username' not in data:
        return jsonify({"error": "Missing 'username' in request body"}), 400

    username = data['username']

    # Query the user by UserID
    user = Users.query.get(user_id)

    if user is None:
        return jsonify({"error": "User not found"}), 404

    # Update the Username
    user.Username = username
    user.UpdatedAtUsername = datetime.now(timezone.utc)  # Update the timestamp

    # Commit the changes to the database
    db.session.commit()

    return jsonify({"message": "Username updated successfully", "user": user.as_dict()}), 200

from sqlalchemy import text

@app.route('/update_bio/<int:user_id>', methods=['PUT'])
def update_bio(user_id):
    data = request.get_json()

    if 'bio' not in data:
        return jsonify({"error": "Missing 'bio' in request body"}), 400

    bio = data['bio']

    # Truy vấn người dùng theo UserID
    user = Users.query.get(user_id)

    if user is None:
        return jsonify({"error": "User not found"}), 404

    # Cập nhật Bio bằng cách sử dụng raw SQL với N
    db.session.execute(
        text("UPDATE Users SET Bio = :bio WHERE UserID = :user_id"),
        {"bio": bio, "user_id": user_id}
    )

    # Commit các thay đổi vào cơ sở dữ liệu
    db.session.commit()

    return jsonify({"message": "Bio updated successfully", "user": user.as_dict()}), 200





from sqlalchemy import text

@app.route('/update_fullname/<int:user_id>', methods=['PUT'])
def update_fullname(user_id):
    # Get the JSON data from the request
    data = request.get_json()

    # Check if 'full_name' is in the request data
    if 'full_name' not in data:
        return jsonify({"error": "Missing 'full_name' in request body"}), 400

    full_name = data['full_name']

    # Query the user by UserID
    user = Users.query.get(user_id)

    if user is None:
        return jsonify({"error": "User not found"}), 404

    # Update the FullName using raw SQL
    db.session.execute(
        text("UPDATE Users SET FullName = :full_name, UpdatedAt = :updated_at WHERE UserID = :user_id"),
        {
            "full_name": full_name,
            "updated_at": datetime.now(timezone.utc),
            "user_id": user_id
        }
    )

    # Commit the changes to the database
    db.session.commit()

    return jsonify({"message": "Full name updated successfully", "user": user.as_dict()}), 200





# OTP service for generating and sending OTP
class OtpService:
    @staticmethod
    def generate_otp():
        return random.randint(1000, 9999)  # Generates a 6-digit OTP

    @staticmethod
    def send_otp(email, otp):
        msg = Message(
            subject='OTP Verification Code From Doune',
            sender=current_app.config['MAIL_DEFAULT_SENDER'],
            recipients=[email]
        )

        msg.body = f"""
        Hello {email},

        We have received your confirmation request. To continue, please enter the OTP code below:

        Your OTP code is: {otp}

        This OTP code will expire after 5 minutes. If you did not request this code, please ignore this email.

        Thank you for using our service!

        Best regards,
        User support team: Doune Support
        Contact Info: 0915878677
        """

        msg.html = f"""
        <html>
            <body>
                <p>Hello {email},</p>
                <p>We have received your confirmation request. To continue, please enter the OTP code below:</p>
                <div style="border: 2px solid #007BFF; border-radius: 5px; padding: 10px; display: inline-block; cursor: pointer;" onclick="this.select();">
                    <strong>Your OTP code is: {otp}</strong>
                </div>
                <p>This OTP code will expire after 5 minutes. If you did not request this code, please ignore this email.</p>
                <p>Thank you for using our service!</p>
                <p>Best regards,<br>User support team: Doune Support<br>Contact Info: 0915878677</p>
            </body>
        </html>
        """

        mail.send(msg)

class VerifyOTP:
    otp_store = {}  # Initialize the OTP store

    @classmethod
    def store_otp(cls, email, otp):
        cls.otp_store[email] = otp  # Store OTP in memory
        print(f"Stored OTP for {email}: {cls.otp_store[email]}")  # Debug print

    @classmethod
    def verify_otp(cls, email, input_otp):
        if email not in cls.otp_store:
            print(f"No OTP found for {email}.")  # Debug print
            return False
        stored_otp = cls.otp_store[email]
        print(f"Verifying OTP for {email}: input={input_otp}, stored={stored_otp}")  # Debug print
        return str(stored_otp) == str(input_otp)  # Ensure both are strings for comparison



class VerifyOTPResource(Resource):
    def post(self):
        data = request.json
        email = data.get('email')
        input_otp = data.get('otp')

        if not email or not input_otp:
            return {"error": "Email and OTP are required."}, 400

        print(f"Received OTP verification request: {data}")

        # Check if the OTP is valid for the given email
        is_valid = VerifyOTP.verify_otp(email, input_otp)
        if is_valid:
            print(f"OTP verified successfully for {email}.")
            return {"message": "OTP verified successfully."}, 200
        else:
            print(f"OTP verification failed for {email}.")
            return {"error": "Invalid OTP."}, 400



def determine_file_type(filename):
    if filename.endswith(('.mp4', '.mov')):
        return 'video'
    elif filename.endswith(('.jpeg', '.jpg', '.png')):
        return 'image'
    return 'unknown'


class Reaction(db.Model):
    __tablename__ = 'reactions'
    id = db.Column(db.Integer, primary_key=True)
    file_id = db.Column(db.String, nullable=False)  # Refers to the video file ID in GridFS
    user_id = db.Column(db.Integer, nullable=False)

class Share(db.Model):
    __tablename__ = 'shares'
    id = db.Column(db.Integer, primary_key=True)
    file_id = db.Column(db.String, nullable=False)
    count = db.Column(db.Integer, default=0)  # Number of times shared

class View(db.Model):
    __tablename__ = 'views'
    id = db.Column(db.Integer, primary_key=True)
    file_id = db.Column(db.String, nullable=False)  # Ensure this matches the type used in the database
    count = db.Column(db.Integer, default=0)


def get_views_count(file_id):
    # Convert file_id to string if it's not already a string
    file_id_str = str(file_id)

    view_record = View.query.filter_by(file_id=file_id_str).first()
    if view_record:
        return view_record.count
    return 0





@app.route('/checkreaction', methods=['GET'])
def check_reaction():
    file_id = request.args.get('file_id')
    user_id = int(request.args.get('user_id'))

    reaction = Reaction.query.filter_by(file_id=file_id, user_id=user_id).first()

    if reaction:
        return jsonify({"liked": True}), 200
    else:
        return jsonify({"liked": False}), 200

@app.route('/react', methods=['POST'])
def react():
    data = request.get_json()
    file_id = data.get('file_id')
    user_id = int(data.get('user_id'))

    print(f"Received file_id: {file_id}")

    # Chuyển đổi file_id thành ObjectId
    try:
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"message": "Invalid file_id format"}), 400

    print(f"Connecting to MongoDB...")
    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})
    print(f"File record found: {file_record}")

    if not file_record:
        return jsonify({"message": "Video not found"}), 404

    # Kiểm tra xem đã có reaction chưa
    existing_reaction = Reaction.query.filter_by(file_id=file_id, user_id=user_id).first()

    if not existing_reaction:
        # Thêm reaction vào SQL Server
        new_reaction = Reaction(file_id=file_id, user_id=user_id)
        db.session.add(new_reaction)
        db.session.commit()

        # Tăng số lượng phản ứng trong MongoDB
        mongo.db.fs.files.update_one(
            {'_id': file_id_obj},
            {'$inc': {'reactions': 1}}
        )

        return jsonify({"message": "Liked video"}), 200
    else:
        return jsonify({"message": "Already liked video"}), 400

@app.route('/unreact', methods=['POST'])
def unreact():
    data = request.get_json()
    file_id = data.get('file_id')
    user_id = int(data.get('user_id'))

    print(f"Received file_id: {file_id}")

    # Chuyển đổi file_id thành ObjectId
    try:
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"message": "Invalid file_id format"}), 400

    print(f"Connecting to MongoDB...")
    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})
    print(f"File record found: {file_record}")

    if not file_record:
        return jsonify({"message": "Video not found"}), 404

    # Kiểm tra xem đã có reaction chưa
    existing_reaction = Reaction.query.filter_by(file_id=file_id, user_id=user_id).first()

    if existing_reaction:
        # Xóa reaction khỏi SQL Server
        db.session.delete(existing_reaction)
        db.session.commit()

        # Giảm số lượng phản ứng trong MongoDB
        mongo.db.fs.files.update_one(
            {'_id': file_id_obj},
            {'$inc': {'reactions': -1}}
        )

        return jsonify({"message": "Unliked video"}), 200
    else:
        return jsonify({"message": "Not liked video"}), 400

class ListFiles(Resource):
    def get(self):
        base_url = request.host_url  # Gets the base URL of the API
        files = []

        # Fetch only files with 'approved' status from GridFS
        for file in fs.find({"metadata.status": "approved"}):
            file_url = f"{base_url}download/{file._id}"  # Construct the full URL
            file_type = determine_file_type(file.filename)  # Determine the file type

            # Initialize user_info as an empty dictionary
            user_info = {}

            # Check if file.metadata exists and is not None
            if file.metadata:
                user_id = file.metadata.get('user_id')  # Retrieve user_id from metadata

                if user_id:  # Check if user_id is present
                    user = Users.query.filter_by(UserID=user_id).first()  # Fetch user from the SQLAlchemy model
                    if user:
                        user_info = {
                            "UserId": user.UserID,
                            "Email": user.Email,
                            "FullName": user.FullName,
                            "Username": user.Username,
                            "ProfilePicture": user.ProfilePicture,
                            "Verified": user.Verified
                        }

                # Retrieve the status from metadata
                status = file.metadata.get('status', 'unknown')  # Default to 'unknown' if not present

            # Fetch reactions and shares
            reaction_count = Reaction.query.filter_by(file_id=str(file._id)).count()
            shares = Share.query.filter_by(file_id=str(file._id)).first()
            share_count = shares.count if shares else 0  # Number of shares

            # Fetch view count
            view_record = View.query.filter_by(file_id=str(file._id)).first()
            view_count = view_record.count if view_record else 0  # Number of views

            # Append file information, user_info, and status to the list
            files.append({
                "user_info": user_info,  # Include user information
                "file_id": str(file._id),
                "filename": file.filename,
                "url": file_url,  # Include the full URL
                "type": file_type,  # Include the file type
                "status": status,  # Include the status
                "reactions": reaction_count,  # Include the number of reactions
                "shares": share_count,  # Include the number of shares
                "views": view_count  # Include the number of views
            })

        # Return the JSON response
        return jsonify(files)


# Resource for downloading videos



fs_thumbnail = gridfs.GridFSBucket(mongo.db, bucket_name='thumbnail')  # Tạo bucket cho thumbnail
class UploadVideo(Resource):
    def post(self):
        if 'file' not in request.files:
            return {"message": "No file part in the request"}, 400

        file = request.files['file']
        if file.filename == '':
            return {"message": "No file selected for uploading"}, 400

        user_id = request.form.get('user_id', type=int)
        if not user_id:
            return {"message": "User ID is required."}, 400

        user = Users.query.filter_by(UserID=user_id).first()
        if not user:
            return {"message": "User not found"}, 404

        filename = secure_filename(file.filename)
        temp_dir = tempfile.mkdtemp()
        temp_file_path = os.path.join(temp_dir, filename)
        file.save(temp_file_path)

        thumbnail_id = None  # Initialize thumbnail_id

        # Check if a thumbnail is provided
        if 'thumbnail' in request.files:
            thumbnail_file = request.files['thumbnail']
            if thumbnail_file.filename != '':
                # Save the provided thumbnail to GridFS
                thumbnail_filename = secure_filename(thumbnail_file.filename)
                thumbnail_stream = thumbnail_file.stream  # Get the file stream

                # Save the thumbnail image to GridFS
                thumbnail_id = fs_thumbnail.upload_from_stream(
                    filename=thumbnail_filename,
                    source=thumbnail_stream,
                    metadata={'user_id': user.UserID}
                )
        else:
            # Handle thumbnail generation if not provided
            thumbnail_path = self.generate_default_thumbnail(temp_file_path)
            if thumbnail_path:
                with open(thumbnail_path, 'rb') as t:
                    thumbnail_id = fs_thumbnail.upload_from_stream(
                        filename=os.path.basename(thumbnail_path),
                        source=t,
                        metadata={'user_id': user.UserID}
                    )

        try:
            # Save video file to GridFS
            with open(temp_file_path, 'rb') as f:
                video_id = fs.put(f, filename=filename, metadata={'user_id': user.UserID, 'status': 'waiting_for_approval'})

            # Update video metadata with thumbnail ID
            mongo.db.fs.files.update_one(
                {"_id": ObjectId(video_id)},
                {"$set": {"metadata.thumbnail_id": str(thumbnail_id)}}
            )

            # Load and classify the video
            model = NUDITYDETECTION.load_model_custom("Nudity-Detection-Model.h5")
            result = NUDITYDETECTION.classify(model, [temp_file_path])

            # Check for inappropriate content
            if isinstance(result, dict) and all(res == 'Content not safe' for res in result.values()):
                mongo.db.fs.files.update_one({"_id": ObjectId(video_id)}, {"$set": {"metadata.status": 'under review'}})
                message = "Video uploaded but requires further review due to inappropriate content."
                status = "under review"
            else:
                mongo.db.fs.files.update_one({"_id": ObjectId(video_id)}, {"$set": {"metadata.status": 'approved'}})
                message = "Video uploaded successfully and approved."
                status = "approved"

            return {
                "message": message,
                "video_id": str(video_id),
                "thumbnail_id": str(thumbnail_id),
                "user_info": {
                    "UserId": user.UserID,
                    "FullName": user.FullName,
                    "Username": user.Username,
                    "ProfilePicture": user.ProfilePicture,
                    "Verified": user.Verified,
                },
                "status": status
            }, 201

        except Exception as e:
            logging.error(f"Error processing the file: {str(e)}", exc_info=True)
            return {"message": f"Error processing the file: {str(e)}"}, 500

        finally:
            shutil.rmtree(temp_dir)

    def generate_default_thumbnail(self, video_path):
        try:
            # Load the video file
            video = VideoFileClip(video_path)

            # Get the duration of the video
            duration = video.duration

            # Set the time (in seconds) to capture the thumbnail (e.g., at 50% of the video length)
            time = duration / 2  # Change this value if you want a different frame

            # Extract the frame at the specified time
            thumbnail_frame = video.get_frame(time)

            # Save the thumbnail image
            thumbnail_path = video_path.replace('.mp4', '_thumbnail.png')
            img = Image.fromarray(thumbnail_frame)
            img.save(thumbnail_path)

            return thumbnail_path
        except Exception as e:
            logging.error(f"Error generating thumbnail: {str(e)}")
            return None

@app.route('/videofeatured', methods=['GET'])
def video_featured():
    user_id = request.args.get('user_id', type=int)

    if not user_id:
        return jsonify({"error": "User ID is required."}), 400

    base_url = request.host_url  # Gets the base URL of the API
    videos = []

    # Fetch only featured files for the given user_id from GridFS
    featured_files = fs.find({"metadata.user_id": user_id, "metadata.featured": True})

    for file in featured_files:

        file_url = f"{base_url}download/{file._id}"  # Construct the full URL
        file_type = determine_file_type(file.filename)  # Determine the file type

        # Initialize user_info as an empty dictionary
        user_info = {}
        user_id = file.metadata.get('user_id')
        if user_id:
            user = Users.query.filter_by(UserID=user_id).first()
            if user:
                user_info = {
                    "UserId": user.UserID,
                    "Email": user.Email,
                    "FullName": user.FullName,
                    "Username": user.Username,
                    "ProfilePicture": user.ProfilePicture,
                    "Verified": user.Verified
                }

        # Retrieve thumbnail_id and generate URL
        thumbnail_id = file.metadata.get('thumbnail_id')
        thumbnail_url = None
        if thumbnail_id:
            try:
                thumbnail_url = f"{base_url}download/{thumbnail_id}/thumbnail"
            except Exception as e:
                print(f"Error generating thumbnail URL: {e}")

        # Fetch reactions, shares, and views in a single query
        reaction_count = Reaction.query.filter_by(file_id=str(file._id)).count()
        shares = Share.query.filter_by(file_id=str(file._id)).first()
        share_count = shares.count if shares else 0
        view_record = View.query.filter_by(file_id=str(file._id)).first()
        view_count = view_record.count if view_record else 0

        # Append video information to the list
        videos.append({
            "user_info": user_info,
            "file_id": str(file._id),
            "filename": file.filename,
            "url": file_url,
            "type": file_type,
            "status": file.metadata.get('status', 'unknown'),
            "reactions": reaction_count,
            "shares": share_count,
            "views": view_count,
            "thumbnail_url": thumbnail_url,
            "featured": file.metadata.get('featured', False)
        })

    return jsonify(videos), 200
        
@app.route('/getuservideofeatured', methods=['GET'])
def get_user_video_featured():
    user_id = request.args.get('user_id', type=int)

    if not user_id:
        return jsonify({"error": "User ID is required."}), 400

    base_url = request.host_url  # Gets the base URL of the API
    videos = []

    # Fetch only featured files for the given user_id from GridFS
    featured_files = fs.find({"metadata.user_id": user_id, "metadata.featured": True})

    for file in featured_files:
        # Skip private videos
        if file.metadata.get('private', False):
            continue

        file_url = f"{base_url}download/{file._id}"  # Construct the full URL
        file_type = determine_file_type(file.filename)  # Determine the file type

        # Initialize user_info as an empty dictionary
        user_info = {}
        user_id = file.metadata.get('user_id')
        if user_id:
            user = Users.query.filter_by(UserID=user_id).first()
            if user:
                user_info = {
                    "UserId": user.UserID,
                    "Email": user.Email,
                    "FullName": user.FullName,
                    "Username": user.Username,
                    "ProfilePicture": user.ProfilePicture,
                    "Verified": user.Verified
                }

        # Retrieve thumbnail_id and generate URL
        thumbnail_id = file.metadata.get('thumbnail_id')
        thumbnail_url = None
        if thumbnail_id:
            try:
                thumbnail_url = f"{base_url}download/{thumbnail_id}/thumbnail"
            except Exception as e:
                print(f"Error generating thumbnail URL: {e}")

        # Fetch reactions, shares, and views in a single query
        reaction_count = Reaction.query.filter_by(file_id=str(file._id)).count()
        shares = Share.query.filter_by(file_id=str(file._id)).first()
        share_count = shares.count if shares else 0
        view_record = View.query.filter_by(file_id=str(file._id)).first()
        view_count = view_record.count if view_record else 0

        # Append video information to the list
        videos.append({
            "user_info": user_info,
            "file_id": str(file._id),
            "filename": file.filename,
            "url": file_url,
            "type": file_type,
            "status": file.metadata.get('status', 'unknown'),
            "reactions": reaction_count,
            "shares": share_count,
            "views": view_count,
            "thumbnail_url": thumbnail_url,
            "featured": file.metadata.get('featured', False)
        })

    return jsonify(videos), 200

@app.route('/updatefeatured', methods=['POST'])
def update_featured():
    data = request.get_json()
    file_id = data.get('file_id')

    if not file_id:
        return jsonify({"error": "File ID is required."}), 400

    try:
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"error": "Invalid file_id format"}), 400

    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})

    if not file_record:
        return jsonify({"error": "Video not found"}), 404

    current_featured_status = file_record.get('metadata', {}).get('featured', False)
    new_featured_status = not current_featured_status

    mongo.db.fs.files.update_one(
        {'_id': file_id_obj},
        {'$set': {'metadata.featured': new_featured_status}}
    )

    return jsonify({"message": "Featured status updated successfully", "featured": new_featured_status}), 200

@app.route('/checkfeatured', methods=['GET'])
def check_featured():
    file_id = request.args.get('file_id')

    if not file_id:
        return jsonify({"error": "File ID is required."}), 400

    try:
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"error": "Invalid file_id format"}), 400

    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})

    if not file_record:
        return jsonify({"error": "Video not found"}), 404

    featured_status = file_record.get('metadata', {}).get('featured', False)

    return jsonify({"featured": featured_status}), 200

@app.route('/updateprivate', methods=['POST'])
def update_private():
    data = request.get_json()
    file_id = data.get('file_id')

    if not file_id:
        return jsonify({"error": "File ID is required."}), 400

    try:
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"error": "Invalid file_id format"}), 400

    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})

    if not file_record:
        return jsonify({"error": "Video not found"}), 404

    current_private_status = file_record.get('metadata', {}).get('private', False)
    new_private_status = not current_private_status

    mongo.db.fs.files.update_one(
        {'_id': file_id_obj},
        {'$set': {'metadata.private': new_private_status}}
    )

    return jsonify({"message": "Private status updated successfully", "private": new_private_status}), 200

@app.route('/checkprivate', methods=['GET'])
def check_private():
    file_id = request.args.get('file_id')

    if not file_id:
        return jsonify({"error": "File ID is required."}), 400

    try:
        file_id_obj = ObjectId(file_id)
    except Exception as e:
        return jsonify({"error": "Invalid file_id format"}), 400

    file_record = mongo.db.fs.files.find_one({'_id': file_id_obj})

    if not file_record:
        return jsonify({"error": "Video not found"}), 404

    private_status = file_record.get('metadata', {}).get('private', False)

    return jsonify({"private": private_status}), 200


class GetUserVideos(Resource):
    def get(self):
        user_ids = request.args.getlist('user_ids', type=int)

        if not user_ids:
            return jsonify({"error": "No user IDs provided"}), 400

        base_url = request.host_url  # Gets the base URL of the API
        videos = []

        # Fetch only approved files for the given user_ids from GridFS
        approved_files = fs.find({"metadata.user_id": {"$in": user_ids}, "metadata.status": "approved"})

        for file in approved_files:
            file_url = f"{base_url}download/{file._id}"  # Construct the full URL
            file_type = determine_file_type(file.filename)  # Determine the file type

            # Initialize user_info as an empty dictionary
            user_info = {}
            user_id = file.metadata.get('user_id')
            if user_id:
                user = Users.query.filter_by(UserID=user_id).first()
                if user:
                    user_info = {
                        "UserId": user.UserID,
                        "Email": user.Email,
                        "FullName": user.FullName,
                        "Username": user.Username,
                        "ProfilePicture": user.ProfilePicture,
                        "Verified": user.Verified
                    }

            # Retrieve thumbnail_id and generate URL
            thumbnail_id = file.metadata.get('thumbnail_id')
            thumbnail_url = None
            if thumbnail_id:
                try:
                    thumbnail_url = f"{base_url}download/{thumbnail_id}/thumbnail"
                except Exception as e:
                    print(f"Error generating thumbnail URL: {e}")

            # Fetch reactions, shares, and views in a single query
            reaction_count = Reaction.query.filter_by(file_id=str(file._id)).count()
            shares = Share.query.filter_by(file_id=str(file._id)).first()
            share_count = shares.count if shares else 0
            view_record = View.query.filter_by(file_id=str(file._id)).first()
            view_count = view_record.count if view_record else 0

            # Append video information to the list
            videos.append({
                "user_info": user_info,
                "file_id": str(file._id),
                "filename": file.filename,
                "url": file_url,
                "type": file_type,
                "status": file.metadata.get('status', 'unknown'),
                "reactions": reaction_count,
                "shares": share_count,
                "views": view_count,
                "thumbnail_url": thumbnail_url
            })

        return jsonify(videos)



class DownloadVideo(Resource):
    def get(self, file_id, file_type='video'):
        try:
            if file_type == 'thumbnail':
                # Fetch thumbnail from the thumbnail bucket
                thumbnail_data = fs_thumbnail.open_download_stream(ObjectId(file_id))
                return send_file(thumbnail_data, download_name='thumbnail.png', as_attachment=True)
            else:
                # Fetch video from the main fs bucket
                video_data = fs.get(ObjectId(file_id))
                return send_file(video_data, download_name=video_data.filename, as_attachment=True)
        except gridfs.errors.NoFile:
            return {"message": "No file found for the given ID"}, 404
        except Exception as e:
            print(f"Error: {e}")
            return {"message": f"Error retrieving the file: {str(e)}"}, 500

# Add the resource with the new endpoint
api.add_resource(DownloadVideo, '/download/<file_id>', '/download/<file_id>/<file_type>')



@app.route('/downloadfile/<file_id>', methods=['GET'])
def test(file_id):
    try:
        file_id = ObjectId(file_id)
        file_record = fs.find_one({"_id": file_id})
        if not file_record:
            abort(404, description="File not found")

        status = file_record.metadata.get('status', '')
        if status not in ['approved', 'under review']:
            abort(403, description="File not approved for download")

        return send_file(
            io.BytesIO(file_record.read()),
            as_attachment=True,
            download_name=file_record.filename,
            mimetype=file_record.content_type
        )

    except gridfs.errors.NoFile:
        abort(404, description="File not found")
    except Exception as e:
        abort(500, description=f"Error occurred: {str(e)}")


#===================================================================================================================================

class UserSignIn(Resource):
    def post(self):
        data = request.json
        if 'Email' not in data or 'Password' not in data:
            return Response(json.dumps({"error": "Email and Password are required."}), status=400, mimetype='application/json')

        user = Users.query.filter_by(Email=data['Email']).first()
        if user is None or not check_password_hash(user.Password, data['Password']):
            return Response(json.dumps({"error": "Invalid email or password"}), status=401, mimetype='application/json')

        # Exclude sensitive data from the response
        user_data = user.as_dict()
        user_data.pop('Password', None)  # Remove the password from the response
        return Response(json.dumps(user_data), status=200, mimetype='application/json')

class CheckEmail(Resource):
    def post(self):
        data = request.json
        if 'email' not in data:
            message = json.dumps({'error': "Email is required."})
            return Response(message, status=400, mimetype='application/json')

        email = data['email']
        email_exists = Users.query.filter_by(Email=email).first() is not None
        message = json.dumps({'exists': email_exists})
        return Response(message, status=200, mimetype='application/json')

class ChangePassword(Resource):
    def post(self):
        data = request.json
        email = data.get('email')
        new_password = data.get('new_password')

        if not email or not new_password:
            return Response(
                response=json.dumps({"success": False, "message": "Email and new password are required."}),
                status=400,
                mimetype='application/json'
            )

        user = Users.query.filter_by(Email=email).first()
        if user is None:
            return Response(
                response=json.dumps({"success": False, "message": "User not found."}),
                status=404,
                mimetype='application/json'
            )

        # Hash the new password and update it
        hashed_password = generate_password_hash(new_password)
        user.Password = hashed_password
        db.session.commit()

        return Response(
            response=json.dumps({"success": True, "message": "Password changed successfully."}),
            status=200,
            mimetype='application/json'
        )


class SendOTP(Resource):
    def post(self):
        data = request.json
        if 'email' not in data:
            return {"error": "Email is required."}, 400

        email = data['email']
        otp = OtpService.generate_otp()
        OtpService.send_otp(email, otp)

        # Store the OTP after sending it
        VerifyOTP.store_otp(email, otp)

        return {"message": "OTP sent successfully."}, 200

class UserSessions(db.Model):
    __tablename__ = 'UserSessions'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('Users.UserID'), nullable=False)
    token = db.Column(db.String(256), nullable=False)  # Or whatever field you use for tokens


class SignOut(Resource):
    def post(self):
        data = request.json
        token = data.get('token')

        if not token:
            return {"error": "Token is required."}, 400

        session = UserSessions.query.filter_by(token=token).first()
        if session:
            db.session.delete(session)
            db.session.commit()
            return {"message": "Signed out successfully."}, 200
        else:
            return {"error": "Invalid token."}, 401

@app.route('/api/users', methods=['GET'])
def get_all_users():
    users = Users.query.filter_by(isBanned=False).all()  # Filter out banned users
    users_list = []

    for user in users:
        # Debug print statements
        print(f"Debug: User ProfilePicture Field - {user.ProfilePicture}")

        # Construct the URL correctly
        profile_picture_url = f'{user.ProfilePicture}'

        print(f"Debug: ProfilePicture URL - {profile_picture_url}")

        user_data = {
            'Email': user.Email,
            'ProfilePicture': profile_picture_url,
            'FullName': user.FullName,
            'id': user.UserID,
            'Username': user.Username,
            'Verified': user.Verified
        }

        users_list.append(user_data)

    return jsonify(users_list), 200


@app.route('/video/<file_id>/view', methods=['POST'])
def increment_view_count(file_id):
    try:
        view_record = View.query.filter_by(file_id=file_id).first()
        if view_record:
            view_record.count += 1
        else:
            view_record = View(file_id=file_id, count=1)

        db.session.add(view_record)
        db.session.commit()

        return jsonify({"message": "View count updated successfully"}), 200
    except Exception as e:
        # Log the error if necessary
        return jsonify({"error": str(e)}), 500


class GetInfoUser(Resource):
    def get(self, email):
        user = Users.query.filter_by(Email=email).first()

        if user is None:
            return {"error": "User not found"}, 404

        user_data = user.as_dict()
        user_data.pop('Password', None)  # Remove the password from the response

        # Fix the profile picture URL
        if 'profile_picture_url' in user_data:
            user_data['profile_picture_url'] = self._fix_url(user_data['profile_picture_url'])

        return jsonify(user_data)

    def _fix_url(self, url):
        if url.startswith('http://localhost:5000/') and not url.startswith('http://localhost:5000/static/uploads/'):
            return url.replace('http://localhost:5000/', 'http://localhost:5000/static/uploads/')
        return url

# Add resource to API with route including username as path parameter
fs_avatar = gridfs.GridFS(mongo.db, collection='fs.avatar')

@app.route('/upload-avatar', methods=['POST'])
def upload_avatar():
    if 'file' not in request.files:
        return jsonify({"message": "No file part in the request"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"message": "No file selected for uploading"}), 400

    # Validate file type
    allowed_extensions = {'jpg', 'jpeg', 'png', 'gif'}
    if '.' not in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
        return jsonify({"message": "File type not allowed. Allowed types are: " + ", ".join(allowed_extensions)}), 400

    user_id = request.form.get('user_id', type=int)
    if not user_id:
        return jsonify({"message": "User ID is required."}), 400

    # Fetch the user from the SQL database
    user = Users.query.filter_by(UserID=user_id).first()
    if user is None:
        return jsonify({"message": "User not found"}), 404

    # Delete the user's previous avatar(s) from GridFS
    existing_files = fs_avatar.find({"metadata.user_id": user_id})
    for old_file in existing_files:
        fs_avatar.delete(old_file._id)

    # Save the new uploaded file to GridFS
    filename = secure_filename(file.filename)
    metadata = {'user_id': user_id}
    file_id = fs_avatar.put(file, filename=filename, metadata=metadata)

    # Construct the file URL
    file_url = f'{file_id}'

    # Update the user's ProfilePicture in the SQL database
    user.ProfilePicture = file_url
    db.session.commit()

    return jsonify({
        "message": "Profile picture uploaded successfully",
        "file_url": file_url,
        "user_info": {
            "UserID": user.UserID,
            "FullName": user.FullName,
            "Username": user.Username,
            "ProfilePicture": user.ProfilePicture
        }
    }), 201
logging.basicConfig(level=logging.INFO)
class Followers(db.Model):
    __tablename__ = 'Followers'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('Users.UserID'), nullable=False)  # User who is following
    follow_id = db.Column(db.Integer, db.ForeignKey('Users.UserID'), nullable=False)  # User being followed

    user = db.relationship('Users', foreign_keys=[user_id], backref='following')
    follower = db.relationship('Users', foreign_keys=[follow_id], backref='followers')

    def as_dict(self):
        return {
            'user_id': self.user_id,
            'follow_id': self.follow_id
        }

class FollowUser(Resource):
    def post(self):
        data = request.json
        follower_id = data.get('follower_id')
        followed_id = data.get('followed_id')

        if not follower_id or not followed_id:
            logging.error("Follower and followed user IDs are required.")
            return {"error": "Follower and followed user IDs are required."}, 400

        follower = Users.query.get(follower_id)
        followed = Users.query.get(followed_id)

        if not follower or not followed:
            logging.error("Follower or followed user not found.")
            return {"error": "Follower or followed user not found."}, 404

        # Check if the follower is already following the followed user
        existing_follow = Followers.query.filter_by(user_id=follower_id, follow_id=followed_id).first()
        if existing_follow:
            logging.info(f"User {follower_id} is already following {followed_id}.")
            return {"message": "You are already following this user."}, 400

        # Increment follower and following counts
        follower.Following += 1
        followed.Follower += 1

        follow_record = Followers(user_id=follower_id, follow_id=followed_id)
        db.session.add(follow_record)
        db.session.commit()

        logging.info(f"User {follower_id} followed {followed_id}.")
        return {"message": "User followed successfully."}, 201


class UnfollowUser(Resource):
    def post(self):
        data = request.json
        follower_id = data.get('follower_id')
        followed_id = data.get('followed_id')

        if not follower_id or not followed_id:
            logging.error("Follower and followed user IDs are required.")
            return {"error": "Follower and followed user IDs are required."}, 400

        follower = Users.query.get(follower_id)
        followed = Users.query.get(followed_id)

        if not follower or not followed:
            logging.error("Follower or followed user not found.")
            return {"error": "Follower or followed user not found."}, 404

        # Check if the follower is following the followed user
        follow_record = Followers.query.filter_by(user_id=follower_id, follow_id=followed_id).first()
        if not follow_record:
            logging.error("Not following this user.")
            return {"error": "Not following this user."}, 404

        # Decrement follower and following counts
        follower.Following -= 1
        followed.Follower -= 1

        db.session.delete(follow_record)
        db.session.commit()

        logging.info(f"User {follower_id} unfollowed {followed_id}.")
        return {"message": "User unfollowed successfully."}, 200

class GetFollowers(Resource):
    def get(self, user_id):
        user = Users.query.get(user_id)
        if not user:
            return {"error": "User not found."}, 404

        followers = Followers.query.filter_by(follow_id=user_id).all()
        followers_list = []
        for f in followers:
            follower_user = Users.query.get(f.user_id)
            if follower_user:
                followers_list.append({
                    'user_id': follower_user.UserID,
                    'username': follower_user.Username,
                    'full_name': follower_user.FullName,
                    'profile_picture': follower_user.ProfilePicture
                })

        return jsonify(followers_list)

class GetFollowing(Resource):
    def get(self, user_id):
        user = Users.query.get(user_id)
        if not user:
            return {"error": "User not found."}, 404

        following = Followers.query.filter_by(user_id=user_id).all()
        following_list = []
        for f in following:
            followed_user = Users.query.get(f.follow_id)
            if followed_user:
                following_list.append({
                    'user_id': followed_user.UserID,
                    'username': followed_user.Username,
                    'full_name': followed_user.FullName,
                    'profile_picture': followed_user.ProfilePicture
                })

        return jsonify(following_list)

class CheckFollowStatus(Resource):
    def post(self):
        data = request.json
        print("Received data:", data)  # Debugging line

        follower_id = data.get('follower_id')
        followed_id = data.get('followed_user_id')

        if not follower_id or not followed_id:
            return {"error": "Follower ID and followed user ID are required."}, 400

        try:
            follower_id = int(follower_id)
            followed_id = int(followed_id)
        except ValueError:
            return {"error": "Invalid user ID format."}, 400

        # Query to check if users exist
        follower = Users.query.get(follower_id)
        followed = Users.query.get(followed_id)

        if not follower:
            return {"error": "Follower not found."}, 404
        if not followed:
            return {"error": "Followed user not found."}, 404

        # Query to check if there is a follow record
        follow_record = Followers.query.filter_by(user_id=follower_id, follow_id=followed_id).first()
        return {"isFollowing": follow_record is not None}, 200



@app.route('/search', methods=['POST'])
def search_keyword():
    data = request.get_json()
    keyword = data.get('keyword')
    user_id = data.get('user_id')  # Nhận ID người dùng từ dữ liệu JSON

    if not keyword or user_id is None:
        response = jsonify({"error": "Keyword or user_id not provided"})
        print("Response:", response.json)
        return response, 400
    try:
        # Chuyển đổi user_id thành số nguyên
        user_id = int(user_id)
    except ValueError:
        response = jsonify({"error": "Invalid user_id format"})
        print("Response:", response.json)
        return response, 400

    # Kiểm tra tính tục tĩu và từ khóa đen
    _, blacklisted_detected = check_profanity_and_similarity([keyword])
    print("Blacklisted Detected:", blacklisted_detected)

    if blacklisted_detected[0]:
        response = jsonify({"error": "Keyword contains profanity or is blacklisted"})
        print("Response:", response.json)
        return response, 400

    # Kiểm tra từ khóa đã được tìm kiếm bởi người dùng này chưa
    keyword_entry = fs_search.find_one({"keyword": keyword, "user_id": user_id})

    if not keyword_entry:
        # Nếu từ khóa chưa được tìm kiếm bởi người dùng này, thêm từ khóa vào collection
        fs_search.insert_one({
            "keyword": keyword,
            "search_count": 1,
            "user_id": user_id  # Lưu ID người dùng
        })
        response = jsonify({"message": "Keyword search recorded successfully"})
        print("Response:", response.json)
        return response, 200
    else:
        # Nếu từ khóa đã được tìm kiếm bởi người dùng này, không thay đổi số lượt tìm kiếm
        response = jsonify({"message": "Keyword already searched by this user"})
        print("Response:", response.json)
        return response, 200

@app.route('/top-search', methods=['GET'])
def get_top_search():
    # Tìm 8 từ khóa có số lượt tìm kiếm nhiều nhất
    top_keywords = fs_search.aggregate([
        {"$group": {
            "_id": "$keyword",  # Từ khóa được nhóm theo
            "search_count": {"$sum": "$search_count"},
            "user_email": {"$addToSet": "$user_email"}  # Lưu danh sách ID người dùng
        }},
        {"$sort": {"search_count": -1}},  # Sắp xếp theo số lượt tìm kiếm giảm dần
        {"$limit": 8}  # Giới hạn kết quả ở 8 từ khóa
    ])

    # Convert the cursor to a list
    top_keywords_list = list(top_keywords)

    # Nếu không có từ khóa nào được tìm thấy
    if len(top_keywords_list) == 0:
        return jsonify({"error": "No keywords found"}), 404

    # Randomly select 5 keywords from the top 8
    random_keywords_list = random.sample(top_keywords_list, min(5, len(top_keywords_list)))

    # Tạo danh sách từ khóa
    result = []
    for keyword in random_keywords_list:
        result.append({
            "keyword": keyword['_id'],  # Sử dụng trường '_id' thay vì '_email'
            "search_count": keyword['search_count'],
            "user_email": keyword['user_email']  # Bao gồm danh sách ID người dùng
        })

    return jsonify(result), 200




@app.route('/download/avatar/<file_id>', methods=['GET'])
def download_avatar(file_id):
    try:
        # Retrieve the file from GridFS by file_id
        file = fs_avatar.get(ObjectId(file_id))

        # Use send_file to send the file as a response
        return send_file(
            io.BytesIO(file.read()),  # Convert file to BytesIO for streaming
            mimetype=file.content_type,  # Set the correct MIME type
            as_attachment=False,  # Display inline, not as an attachment
            download_name=file.filename  # Provide a filename for the file
        )
    except gridfs.errors.NoFile:
        return jsonify({"message": "File not found"}), 404

class GetUserByID(Resource):
    def get(self, user_id):
        # Query the database for the user with the provided user_id
        user = Users.query.get(int(user_id))

        if user:
            user_data = user.as_dict()
            user_data.pop('Password', None)
            user_data.pop('Email', None)

            # Retrieve the profile picture URL from GridFS if available
            profile_picture_id = user_data.get('ProfilePicture')
            if profile_picture_id:
                # Construct the URL for the avatar
                profile_picture_url = f'{profile_picture_id}'
                user_data['ProfilePictureURL'] = profile_picture_url
            else:
                user_data['ProfilePictureURL'] = None

            return jsonify(user_data)  # Return user data as a JSON response
        else:
            return jsonify({"error": "User not found"}), 404
            # Return a 404 error if user is not found

class GetInfoUserByUsername(Resource):
    def get(self, username):
        # Query the user by username
        user = Users.query.filter_by(Username=username).first()

        if user is None:
            return {"error": "User not found"}, 404

        # Convert user data to dictionary
        user_data = user.as_dict()

        # Remove sensitive information
        user_data.pop('Password', None)  # Remove the password from the response

        # Retrieve the profile picture URL from GridFS if available
        profile_picture_id = user_data.get('ProfilePicture')
        if profile_picture_id:
            # Construct the URL for the avatar
            profile_picture_url = f'/download/avatar/{profile_picture_id}'
            user_data['ProfilePictureURL'] = profile_picture_url
        else:
            user_data['ProfilePictureURL'] = None

        return jsonify(user_data)


# Add the resource to the API
api.add_resource(GetUserByID, '/user-by-id/<int:user_id>')
api.add_resource(CheckFollowStatus, '/check')
api.add_resource(FollowUser, '/follow')
api.add_resource(UnfollowUser, '/unfollow')
api.add_resource(GetFollowers, '/followers/<int:user_id>')
api.add_resource(GetFollowing, '/following/<int:user_id>')
api.add_resource(GetInfoUserByUsername, '/user-by-username/<string:username>')
api.add_resource(GetUserVideos, '/user-videos')
api.add_resource(GetInfoUser, '/user/<string:email>')
api.add_resource(UploadVideo, '/upload')
api.add_resource(ListFiles, '/files')
api.add_resource(UserSignUp, '/signup')
api.add_resource(UserSignIn, '/signin')
api.add_resource(CheckEmail, '/checkemail')
api.add_resource(SendOTP, '/send-otp')
api.add_resource(VerifyOTPResource, '/verify-otp')
api.add_resource(ChangePassword, '/change-password')
api.add_resource(SignOut, '/signout')

# Swagger UI setup
@app.route("/swagger")
def swagger_ui():
    return render_template('swaggerui.html')

if __name__ == "__main__":
    with app.app_context():
        db.create_all()  # Tạo các bảng database nếu chưa tồn tại
    socketio.run(app, host='127.0.0.1', port=5000, debug=True)